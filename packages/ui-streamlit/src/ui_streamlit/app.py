import streamlit as st
from football_common import about

st.title("Football Lakehouse – Hello")
st.success(about())
st.write("If you can read this, Streamlit + workspace import works 🎉")
