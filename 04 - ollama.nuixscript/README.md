# Ollama API

The prompt needs to contain the value `{document}` which gets replaced with the item text. 

An example prompt could be:
```
You are a document assistant. Please answer the following questions about the document:<document>{document}</document>

1. Summarize the content of the document. (key: summary)
2. What are important keywords in the document?  (key: keywords)

Answer in german and return valid json.
```

**Drawbacks:**
Currently items text is not splitted into chunks so depending on the text length the context could be lost.

**Important:** The search query needs to include `AND has-text:1` to match only items with text.
