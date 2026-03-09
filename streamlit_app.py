import streamlit as st
import json
import _snowflake
from snowflake.snowpark.context import get_active_session

st.set_page_config(layout="wide")

st.title("📦 MCC Product Assistant")
st.caption("Ask questions about MCC product datasheets, specifications, and curves")

session = get_active_session()

AGENT_DATABASE = "PRODUCT_DATA_AGENT"
AGENT_SCHEMA = "AGENTS"
AGENT_NAME = "MCC_PRODUCT_CHATBOT"

if "messages" not in st.session_state:
    st.session_state.messages = []

if "input_key" not in st.session_state:
    st.session_state.input_key = 0

def get_relevant_images(question: str, citations: list, response_text: str = "") -> list:
    """Find images semantically similar to the question using vector embeddings."""
    import re
    products = set()
    
    for citation in citations:
        text = citation.get("text", "")
        matches = re.findall(r'(MBRB4040CTQ|2N7002|SICW025N120Y|SMB10J[^\s\)]*)', text)
        products.update(matches)
    
    if response_text:
        matches = re.findall(r'(MBRB4040CTQ|2N7002|SICW025N120Y|SMB10J[^\s\)]*)', response_text)
        products.update(matches)
    
    if not products:
        return []
    
    product_filter = " OR ".join([f"image_filename ILIKE '%{p}%'" for p in products])
    
    query = f"""
        SELECT 
            image_label,
            image_filename,
            source_file,
            GET_PRESIGNED_URL(
                @PRODUCT_DATA_AGENT.DATA.EXTRACTED_IMAGES_STAGE, 
                image_filename, 
                3600
            ) as image_url,
            VECTOR_COSINE_SIMILARITY(
                SNOWFLAKE.CORTEX.EMBED_TEXT_768('e5-base-v2', image_label),
                SNOWFLAKE.CORTEX.EMBED_TEXT_768('e5-base-v2', '{question.replace("'", "''")}')
            ) as similarity
        FROM PRODUCT_DATA_AGENT.DATA.IMAGE_METADATA
        WHERE ({product_filter})
        AND image_label != 'Unknown'
        AND image_label NOT ILIKE '%layout%'
        AND image_label NOT ILIKE '%outline%'
        AND image_label NOT ILIKE '%package%'
        ORDER BY similarity DESC
        LIMIT 1
    """
    
    try:
        results = session.sql(query).collect()
        images = []
        for row in results:
            if row["SIMILARITY"] >= 0.85:
                images.append({
                    "label": row["IMAGE_LABEL"],
                    "url": row["IMAGE_URL"],
                    "source": row["SOURCE_FILE"],
                    "similarity": float(row["SIMILARITY"])
                })
        return images
    except Exception as e:
        return []

def call_agent(question: str) -> tuple:
    try:
        request_body = {
            "model": "claude-3-5-sonnet",
            "messages": [
                {
                    "role": "user",
                    "content": [{"type": "text", "text": question}]
                }
            ]
        }
        
        resp = _snowflake.send_snow_api_request(
            "POST",
            f"/api/v2/databases/{AGENT_DATABASE}/schemas/{AGENT_SCHEMA}/agents/{AGENT_NAME}:run",
            {},
            {},
            request_body,
            {},
            60000
        )
        
        if resp["status"] == 200:
            response_text = ""
            citations = []
            content = resp.get("content", "")
            
            if isinstance(content, str):
                events = json.loads(content)
            else:
                events = content
            
            st.session_state["debug_events"] = events
            
            for event in events:
                event_type = event.get("event", "")
                data = event.get("data", {})
                
                if "text" in event_type.lower() and "delta" in event_type.lower():
                    response_text += data.get("text", "")
                
                if event_type == "response.text.annotation":
                    annotation = data.get("annotation", {})
                    if annotation.get("type") == "cortex_search_citation":
                        citations.append({"text": annotation.get("text", "")})
            
            return response_text if response_text else "No text response found.", citations
        else:
            return f"Error: {resp.get('status')} - {resp.get('content', 'Unknown error')}", []
            
    except Exception as e:
        return f"Error calling agent: {str(e)}", []

def process_question(question: str):
    st.session_state.messages.append({"role": "user", "content": question})
    
    with st.spinner("Thinking..."):
        response, citations = call_agent(question)
        images = get_relevant_images(question, citations, response)
    
    st.session_state.messages.append({
        "role": "assistant", 
        "content": response,
        "images": images
    })
    st.session_state.input_key += 1

with st.sidebar:
    st.header("About")
    st.write("""
    This assistant answers questions about MCC semiconductor products using:
    - Product datasheets
    - Curve/graph data extracted with AI
    - Package specifications
    """)
    
    if st.button("Clear Chat"):
        st.session_state.messages = []
        st.session_state.input_key += 1
        st.experimental_rerun()
    
    if "debug_events" in st.session_state:
        with st.expander("DEBUG - Raw Events"):
            st.text_area("Copy JSON below:", json.dumps(st.session_state["debug_events"], indent=2), height=300)

st.subheader("Try asking:")
col1, col2 = st.columns(2)
with col1:
    if st.button("What is reverse voltage at 500pF capacitance?", use_container_width=True):
        process_question("What is the reverse voltage when junction capacitance is 500pF for MBRB4040CTQ?")
        st.experimental_rerun()
    if st.button("Show forward current derating", use_container_width=True):
        process_question("Show me the forward current derating curve for MBRB4040CTQ")
        st.experimental_rerun()
with col2:
    if st.button("Max forward current at 125°C?", use_container_width=True):
        process_question("What is the maximum forward current at 125°C for MBRB4040CTQ?")
        st.experimental_rerun()
    if st.button("SICW025N120Y capacitance characteristics", use_container_width=True):
        process_question("What are the capacitance characteristics of the SICW025N120Y?")
        st.experimental_rerun()

st.divider()

for msg in st.session_state.messages:
    if msg["role"] == "user":
        st.markdown(f"**🧑 You:** {msg['content']}")
    else:
        st.markdown(f"**🤖 Assistant:** {msg['content']}")
        if msg.get("images"):
            st.write("**Related Curves:**")
            cols = st.columns(min(len(msg["images"]), 4))
            for i, img in enumerate(msg["images"]):
                with cols[i]:
                    st.image(img["url"], caption=img["label"], use_column_width=True)
    st.divider()

with st.form(key=f"question_form_{st.session_state.input_key}", clear_on_submit=True):
    user_input = st.text_input("Ask about MCC products...", key=f"input_{st.session_state.input_key}")
    submit = st.form_submit_button("Send")
    
    if submit and user_input:
        process_question(user_input)
        st.experimental_rerun()
