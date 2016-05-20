# Exposing Oracle REST Data Services using Swagger

This PL/SQL script generates a swagger YAML from Oracle REST Data Services configuration

### Steps to generate the swagger YAML file

Edit the ords2swagger.sql and customize the START PARAMETERS
Run the following command

	$ sqlplus system/<password> @ords2swagger.sql | expand > swaggerfile.yaml


