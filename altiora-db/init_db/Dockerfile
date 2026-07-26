FROM dpage/pgadmin4:9
 
USER root
 
# Copiamos el script que arma la config al vuelo
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
 
USER pgadmin
 
ENTRYPOINT ["/docker-entrypoint.sh"]
