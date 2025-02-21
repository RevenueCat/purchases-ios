require 'json'
require 'open3'
require 'mustache'
require 'tmpdir'

# Configuration
REPO_URL = 'https://github.com/RevenueCat/khepri.git' 
SWIFT_TEMPLATE = 'customer_center.stencil'
OUTPUT_FILE = 'Generated.swift'

Dir.mktmpdir do |tmp_dir|
  CLONE_DIR = File.join(tmp_dir, 'cloned_repo')

  puts "Cloning repository into temporary directory using GitHub CLI (shallow clone)..."
  system("gh repo clone #{REPO_URL} #{CLONE_DIR} -- --depth=1")

  # Set up a virtual environment
  venv_dir = File.join(CLONE_DIR, 'venv')
  system("python3 -m venv #{venv_dir}")
  python_exec = File.join(venv_dir, 'bin', 'python3')
  pip_exec = File.join(venv_dir, 'bin', 'pip')

  # Upgrade pip
  system("#{pip_exec} install --upgrade pip")

  # Install only the necessary dependencies
  system("#{pip_exec} install pydantic validators")

  # Python script to extract Pydantic schema
  python_script = <<~PYTHON
import json
import inspect
import typing
from pydantic import BaseModel
from khepri.services.customer_center.domain.schemas import appearance  # Adjust import path accordingly

def get_pydantic_models(module):
    """Dynamically find all Pydantic models in a module."""
    return [
        obj for name, obj in inspect.getmembers(module)
        if inspect.isclass(obj) and issubclass(obj, BaseModel) and obj is not BaseModel
    ]

def clean_annotation(annotation):
    """Convert Python type annotations to a simpler format for Mustache."""
    annotation_str = str(annotation)
    
    # Check if the field is Optional
    is_optional = "typing.Optional" in annotation_str or "NoneType" in annotation_str

    # Mapping common Python types to Swift
    if "str" in annotation_str:
        return "String", is_optional
    if "int" in annotation_str:
        return "Int", is_optional
    if "float" in annotation_str:
        return "Double", is_optional
    if "bool" in annotation_str:
        return "Bool", is_optional
    if "HexColor" in annotation_str:
        return "String", is_optional  # Handle custom HexColor type as String
    if "typing.Optional" in annotation_str:
        return clean_annotation(annotation.__args__[0])  # Extract the inner type of Optional
    if "typing.Annotated" in annotation_str:
        return clean_annotation(annotation.__args__[0])  # Extract the base type of Annotated
    if annotation_str.startswith("<class '"):
        return annotation_str.split(".")[-1][:-2], is_optional  # Extract model class names like "Theme"

    return "Any", is_optional  # Default to Any for unknown types

def extract_schema(model):
    """Extracts model fields and their cleaned-up annotations, including optional flag."""
    return {
        "model_name": model.__name__,
        "fields": [
            {
                "field": name,
                "type": clean_annotation(field.annotation)[0],
                "is_optional": clean_annotation(field.annotation)[1]
            }
            for name, field in getattr(model, "model_fields", {}).items()
        ]
    }

# Dynamically retrieve all Pydantic models from the module
models = get_pydantic_models(appearance)

# Extract schemas and convert to the desired format
schema_dict = {"models": [extract_schema(model) for model in models]}

# Print JSON output
print(json.dumps(schema_dict, indent=2))

  PYTHON

  # Write Python script to a temporary file in the cloned repository
  python_script_path = File.join(CLONE_DIR, 'extract_schema.py')
  File.write(python_script_path, python_script)

  # Run the Python script
  output, error, status = Open3.capture3("#{python_exec} #{python_script_path}")

  raise "Error parsing Pydantic schema: #{error}" unless status.success?

  schema_data = JSON.parse(output)
  puts schema_data

  # Load Stencil template
  stencil_template = File.read(SWIFT_TEMPLATE)
  
  swift_code = Mustache.render(stencil_template, schema_data)

  File.write(OUTPUT_FILE, swift_code)
  puts "Swift code generated in #{OUTPUT_FILE}"
end
