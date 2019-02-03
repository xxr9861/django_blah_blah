#! /bin/bash

# create the virtual environment
# create the parent project
# create the apps


# create the apps
# is this the app directory
# confirm the files that i expect are present
# source the executables
# command to create the app
# do the relevant changes
   


# prompt the user for the name of the app
populate_adminpy(){
#xxx/admin.py

    cat <<EOF

from django.contrib import admin
from .models import Post

admin.site.register(Post)

EOF

}>>$name_of_app/admin.py

create_superuser(){

python3 manage.py migrate admin
python3 manage.py migrate auth
python3 manage.py migrate contenttypes
python3 manage.py migrate sessions

python3 manage.py createsuperuser

}

usage(){
cat <<EOF

this would go inside the mysite directory
you would have to create the app


EOF
}


populate_modelspy(){
cat <<EOF 

from django.conf import settings                                                                       
from django.db import models                                                                           
from django.utils import timezone                                                                      
                                                                                                       
                                                                                                       
class Post(models.Model):                                                                              
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)                     
    title = models.CharField(max_length=200)                                                           
    text = models.TextField()                                                                          
    created_date = models.DateTimeField(default=timezone.now)                                          
    published_date = models.DateTimeField(blank=True, null=True)                                       
                                                                                                       
    def publish(self):                                                                                 
        self.published_date = timezone.now()                                                           
        self.save()                                                                                    
                                                                                                       
    def __str__(self):                                                                                 
        return self.title                                                                              

EOF

}>>$name_of_app/models.py


functionx(){

python3 manage.py startapp $name_of_app
echo "hit enter to continue"
read junk

# update app/settings.py
# open mysite/settings.py, look for the installed_app list, append $name_of_app 
echo \'$name_of_app\', | xclip
echo "now open new terminal in screen and go to settings.py, search for installed_app list and paste the clipboard content"
#xterm -e "emacs -nw ./settings.py" #see if you can open another terminal for this
read junk
# populate $name_of_app/models.py


populate_modelspy 

python3 manage.py makemigrations $name_of_app

python3 manage.py migrate $name_of_app

populate_adminpy
# create superuser (only for first time i guess)
echo "you might not want to create a superuser, if so then cancel with ctrl plus c"
echo "press enter to continue"
read junk
create_superuser

}

echo "assuming i am in the correct directory"
test_file(){
if [ $(ls ./manage.py) ]
   then
   echo "manage.py found"
else
   echo "manage.py not found"
    fi 
} 2> /dev/null

test_file

echo "continue? "
read junk
which python
echo "continue? "
read junk
source ./../bin/activate
which python
echo "continue? "
read junk
python3 -m django --version
echo $PWD
root_directory="$(realpath . | xargs -d"/" -n1 | tail -n 2 | tr -d '\040\011\012\015')"
echo $root_directory

echo "continue? "
read junk

echo "Enter the name of the app: "
read name_of_app

functionx

# at the end run the server with
# python3 manage.py runserver
# not python manage.py runserver
# next step is fixing the urls file
