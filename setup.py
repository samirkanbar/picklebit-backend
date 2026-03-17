import os
import re
import yaml
from pathlib import Path

def get_all_files_and_types(directory="src"):
    all_files_and_types = []
    TYPE_PATTERN = r'\"\"\"TYPE:\s*(.*?)\"\"\"'
    HANDLER_PATTERN = r'def\s*handler\s*\('
    
    # Use Pathlib to find all .py files in src/routes
    base_path = Path(directory) / "routes"
    
    # rglob finds all .py files recursively inside src/routes
    for file_path in base_path.rglob("*.py"):
        with open(file_path, 'r') as f:
            content = f.read()
            type_match = re.search(TYPE_PATTERN, content)
            handler_match = re.search(HANDLER_PATTERN, content)
            
            if type_match and handler_match:
                # Convert Path object to string for the rest of the script
                all_files_and_types.append((str(file_path), type_match.group(1)))
                
    return all_files_and_types

def generate_functions_dict(files_and_types):
    functions_dict = {}
    for file, type_value in files_and_types:
        # Standardize pathing to forward slashes
        clean_path = file.replace("\\", "/").replace(".py", "")
        
        # Create a unique function name for AWS
        function_name = clean_path.replace("src/routes/", "").replace("/", "_")
        function_name = function_name.replace("{", "").replace("}", "")
        if function_name.endswith("_index"):
            function_name = function_name[:-6]
        if not function_name: function_name = "index"

        handler = clean_path + ".handler"
        
        # Determine the API Path
        route_temp = clean_path.split("src/routes/")[-1]
        if route_temp.endswith("/index"):
            route_temp = route_temp[:-6]
        if route_temp == "index":
            route_temp = ""
        
        method_type = type_value.split(" ")[0].lower()
        
        function_data = {
            "timeout": 20,
            "handler": handler,
            "events": [{"httpApi": {"method": method_type, "path": "/" + route_temp.lstrip("/")}}],
            "layers": [{ "Ref": "PythonRequirementsLambdaLayer" }]
        }
        functions_dict[function_name] = function_data
    return functions_dict

def generate_serverless_yml(files_and_types):
    serverless_config = {
        "service": "picklebit-backend",
        "frameworkVersion": '3',
        "useDotenv": True,
        "provider": {
            "name": "aws",
            "runtime": "python3.11",
            "region": "us-east-2", # Ohio
            "stage": "${opt:stage, 'prod'}",
            "vpc": {
                # Hardcoded Picklebit VPC IDs
                "securityGroupIds": ["sg-0969fd4e50e56c0c0"], 
                "subnetIds": [
                    "subnet-0eafaa3c7f3ac2ebb",
                    "subnet-0058f0e451fa765c8",
                    "subnet-04cf165420f395a9c"
                ]
            }
        },
        "package": {
            "patterns": [
                '!node_modules/**', 
                '!package-lock.json', 
                '!package.json', 
                '!.env', 
                '!venv/**', 
                '!.pytest_cache/**'
            ]
        },
        "plugins": [
            "serverless-python-requirements",
            "serverless-dotenv-plugin"
        ],
        "custom": {
            "pythonRequirements": {
                "dockerizePip": "true", # Necessary for compiling psycopg2
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
    files_and_types = get_all_files_and_types()
    if not files_and_types:
        print("Warning: No route files found in src/routes/ with proper TYPE and handler.")
    generate_serverless_yml(files_and_types)
    print("Successfully generated serverless.yml with VPC IDs.")