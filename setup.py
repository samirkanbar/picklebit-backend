import os
import re
import yaml
from pathlib import Path

def get_all_files_and_types(directory="src"):
    all_files_and_types = []
    # Regex pattern: looks for """TYPE: SOMETHING"""
    TYPE_PATTERN = r'\"\"\"TYPE:\s*(.*?)\"\"\"'
    HANDLER_PATTERN = r'def\s*handler\s*\('
    
    # Standardize path for Mac/Linux
    base_path = Path(os.getcwd()) / directory / "routes"
    
    print(f"DEBUG: Searching in: {base_path}")
    
    if not base_path.exists():
        print(f"❌ ERROR: The directory {base_path} does not exist!")
        return []

    # Find all .py files recursively
    py_files = list(base_path.rglob("*.py"))
    print(f"DEBUG: Found {len(py_files)} total .py files in routes folder.")

    for file_path in py_files:
        # Skip hidden files or __init__.py
        if file_path.name.startswith((".", "__")):
            continue
            
        with open(file_path, 'r') as f:
            content = f.read()
            type_match = re.search(TYPE_PATTERN, content)
            handler_match = re.search(HANDLER_PATTERN, content)
            
            if type_match and handler_match:
                print(f"✅ MATCH: {file_path.name} (Type: {type_match.group(1)})")
                all_files_and_types.append((str(file_path), type_match.group(1)))
            else:
                # Tell us EXACTLY why it failed
                reasons = []
                if not type_match: reasons.append("Missing '\"\"\"TYPE: ...\"\"\"' comment")
                if not handler_match: reasons.append("Missing 'def handler(' function")
                print(f"⚠️  SKIPPED: {file_path.name} -> {', '.join(reasons)}")
                
    return all_files_and_types

def generate_functions_dict(files_and_types):
    functions_dict = {}
    for file, type_value in files_and_types:
        # Standardize to forward slashes for the YAML config
        clean_path = file.replace("\\", "/")
        
        # Get relative path from the project root (e.g., src/routes/users/index)
        try:
            relative_path = clean_path.split("src/routes/")[-1].replace(".py", "")
        except IndexError:
            continue

        # Create function name (e.g., users_index)
        function_name = relative_path.replace("/", "_").replace("{", "").replace("}", "")
        if function_name.endswith("_index"):
            function_name = function_name[:-6]
        if not function_name: function_name = "index"

        handler_path = f"src/routes/{relative_path}.handler"
        
        # Determine API Path
        api_path = relative_path
        if api_path.endswith("/index"):
            api_path = api_path[:-6]
        if api_path == "index":
            api_path = ""
        
        method_type = type_value.split(" ")[0].lower()
        
        functions_dict[function_name] = {
            "timeout": 20,
            "handler": handler_path,
            "events": [{"httpApi": {"method": method_type, "path": "/" + api_path.lstrip("/")}}],
            "layers": [{ "Ref": "PythonRequirementsLambdaLayer" }]
        }
    return functions_dict

def generate_serverless_yml(files_and_types):
    serverless_config = {
        "service": "picklebit-backend",
        "frameworkVersion": '3',
        "useDotenv": True,
        "provider": {
            "name": "aws",
            "runtime": "python3.11",
            "region": "us-east-2",
            "stage": "${opt:stage, 'prod'}",
            "vpc": {
                "securityGroupIds": ["sg-0969fd4e50e56c0c0"], 
                "subnetIds": [
                    "subnet-0eafaa3c7f3ac2ebb",
                    "subnet-0058f0e451fa765c8",
                    "subnet-04cf165420f395a9c"
                ]
            }
        },
        "package": {
            "patterns": ['!node_modules/**', '!package-lock.json', '!package.json', '!.env', '!venv/**']
        },
        "plugins": [
            "serverless-python-requirements",
            "serverless-dotenv-plugin"
        ],
        "custom": {
            "pythonRequirements": {
                "dockerizePip": "true",
                "layer": "true",
                "slim": "true",
                "zip": "true"
            }
        },
        "functions": generate_functions_dict(files_and_types)
    }
    
    with open("serverless.yml", "w") as f:
        yaml.dump(serverless_config, f, default_flow_style=False, sort_keys=False)

if __name__ == "__main__":
    print("--- STARTING SETUP ---")
    files = get_all_files_and_types()
    
    if not files:
        print("🛑 Result: No valid routes found. serverless.yml NOT updated.")
    else:
        generate_serverless_yml(files)
        print(f"🚀 Success: serverless.yml updated with {len(files)} functions.")
    print("--- SETUP COMPLETE ---")