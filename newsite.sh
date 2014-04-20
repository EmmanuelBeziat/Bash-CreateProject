#!/bin/bash

## Création de tout le bazar de configuration Apache/Nginx
## Emmanuel B.
## 20/04/2014

## variables
nomProjet=$1
extension=$2
sousDossier=$3

# Vérification de projet
function VerifierNomProjet {
	# S'il n'ya a pas de nom, en demande un
	if [ -z $nomProjet ]
	then
		read -p "Entrez le nom du projet (pas d'espaces, maximum 30 caractères) : " -n 30 nomProjet

	# Si le projet existe déjà, demander un autre nom
	elif [ -f ../etc/apache2/sites-available/$nomProjet.$extension ]
	then
		echo "Ce nom de projet est déjà utilisé. Choisissez un nouveau nom (pas d'espaces, maximum 30 caractères) : " -n 30 nomProjet
		read -p "Entrez une extension de site web : " -n 4 extension
	fi

	# S'il n'y a pas d'extension, demander
	if [ -z $extension ]
	then
		read -p "Entrez une extension de site web : " -n 4 extension
	fi
}

# Créer le répertoire www
function CreerDossierWeb {
	if [ -z $sousDossier ]
	then
		mkdir -p "/var/www/$nomProjet/"
	else
		mkdir -p  "/var/www/$sousDossier/$nomProjet/"
	fi
}

#Créer le répertoire log
function CreerDossierLog {
	mkdir -p "/var/log/apache2/$nomProjet/"
}

# Créer le fichier de configuration Apache
function CreerFichierApache {
	# Créer le fichier
	local fichier='/etc/apache2/sites-available/'$nomProjet'.'$extension

	# Écrire la configuration dans le fichier
	echo '<VirtualHost 127.0.0.1:8082>
	ServerName www.'$nomProjet'.'$extension'
	ServerAlias www.'$nomProjet'.'$extension'
	ServerAdmin contact@'$nomProjet'.'$extension'

	DocumentRoot /var/www/'$nomProjet'

	ErrorLog ${APACHE_LOG_DIR}/'$nomProjet'/site_error.log
	CustomLog ${APACHE_LOG_DIR}/'$nomProjet'/site_access.log combined
</VirtualHost>

<VirtualHost 127.0.0.1:8082>
	ServerName '$nomProjet'.'$extension'
	ServerAlias '$nomProjet'.'$extension'

	Redirect permanent / http://www.'$nomProjet'.'$extension'/
</VirtualHost>' > $fichier

	# Activer le fichier dans la configuration Apache
	a2ensite $nomProjet.$extension

	#relancer Apache
	service apache2 restart
}

# Créer le fichier de configuration Nginx
function CreerFichierNginx {
	# Créer le fichier
	local fichier='/etc/nginx/sites-available/'$nomProjet'.'$extension

	# Écrire la configuration dans le fichier
	echo 'server {
	listen   80;
	server_name www.'$nomProjet'.'$extension';
	#access_log  /var/log/'$nomProjet'.access.log;
 	#error_log  /var/log/'$nomProjet'.nginx_error.log info;

	access_log	off;

	location = /robots.txt  { access_log off; log_not_found off; }
	location = /favicon.ico { access_log off; log_not_found off; }
	location / {
		proxy_pass         http://127.0.0.1:8082/;
		include  /etc/nginx/conf.d/proxy.conf;
		root /var/www/'$nomProjet'/site;
	}

	location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|txt|srt|swf)$ {
		root  /var/www/'$nomProjet'/site/;
		expires           30d;
	}
}' > $fichier

	# Activer le fichier dans la configuration Nginx
	ln -s /etc/nginx/sites-available/$nomProjet.$extension /etc/nginx/sites-enabled/

	#relancer Nginx
	service nginx restart
}

# Inifialiser la création
function CreerProjet {
	# Vérifier que le nom soit bon
	VerifierNomProjet

	# Créer le dossier log
	CreerDossierLog

	# Créer le dossier web
	CreerDossierWeb

	# Créer fichier de configuration Apache
	CreerFichierApache

	# Créer fichier de configuration Nginx
	CreerFichierNginx

	echo "C'est terminé !"
}

## INITIALISATION, BABY !
CreerProjet
