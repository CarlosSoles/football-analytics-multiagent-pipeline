# Creación del entorno virtual
python -m venv .analytics

# Activación del entorno virtual
.analytics\Scripts\activate

# Actualizar Gestor de Paquetes
python -m pip install --upgrade pip

# Librería base de este proyecto
pip install requests beautifulsoup4 mysql-connector-python python-dotenv