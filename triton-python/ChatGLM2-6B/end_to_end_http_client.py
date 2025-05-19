import requests

data = {
    "inputs": [
        {
            "name": "QUERY",
            "shape": [1, 1],
            "datatype": "BYTES",
            "data": ["川普是不是四川人"],
        },
        {
            "name": "max_new_tokens",
            "shape": [1, 1],
            "datatype": "UINT32",
            "data": [15000],
        },
    ]
}
headers = {
    "Content-Type": "application/json",
}
response = requests.post(
    "http://localhost:8000/v2/models/chatglm2-6b/infer", headers=headers, json=data
)
result = response.json()
print(result)
