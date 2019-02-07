#! /bin/bash

# ::YOU ARE HERE::::YOU ARE HERE::::YOU ARE HERE::::YOU ARE HERE::::YOU ARE HERE::::YOU ARE HERE::
# make sure you are not in the home directory
# https://tutorial.djangogirls.org
# copied from https://tutorial.djangogirls.org




conti(){

    echo "hit enter to continue"
    read junk
    clear
}

# create the virtual environment : would expect user to be in a subdirectory, not the home, if home directory then exit. that would be nice

echo "create virtual environment?"
conti
virtualenv .
conti
echo "name of your django project"
read django_project
source ./bin/activate
which python
echo "$(echo $PWD)"
django-admin startproject $django_project
conti
cd $django_project

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
conti


# update app/settings.py
# open mysite/settings.py, look for the installed_app list, append $name_of_app 
echo \'$name_of_app\', | xclip -selection clipboard
echo "now open new terminal in screen and go to $django_project/settings.py, search for installed_app list and paste the clipboard content"
#xterm -e "emacs -nw ./settings.py" #see if you can open another terminal for this
conti
# populate $name_of_app/models.py


populate_modelspy 

python3 manage.py makemigrations $name_of_app

python3 manage.py migrate $name_of_app

populate_adminpy
# create superuser (only for first time i guess)
echo "you might not want to create a superuser, if so then cancel with ctrl plus c"
echo "press enter to continue"
conti
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
conti

which python
conti
source ./../bin/activate # this has already been done, sort of redundant
which python
conti
python3 -m django --version
echo $PWD
root_directory="$(realpath . | xargs -d"/" -n1 | tail -n 2 | tr -d '\040\011\012\015')"
echo $root_directory # this is the same as $django_project

conti

echo "Enter the name of the app: "
read name_of_app

functionx

# at the end run the server with
# python3 manage.py runserver
# not python manage.py runserver
# next step is fixing the urls file


# change the urls file
echo "change your urls file"

cat <<eof


from django.contrib import admin
from django.urls import path, include

urlpatterns = [
path(admin/, admin.site.urls),
path("", include('$name_of_app.urls')),
]
## important 
## from django.urls import path, include
## import include
eof
conti

echo " path('', include('$name_of_app.urls'))," | xclip -selection clipboard
# for this to work,
# ssh -X ip
# use xclip -selection clipboard.el in emacs
echo "open another terminal and go to $django_project/urls.py and paste clipboard contents"

conti
echo "replace the following in $django_project/urls.py"
echo "from django.urls import path"
echo 
echo "           with the following:"
echo
echo "from django.urls import path, include"
echo "from django.urls import path, include" | xclip -selection clipboard

echo "open another terminal and go to $django_project/urls.py and paste clipboard contents"

conti




# blog/urls.py
echo "create $name_of_app/urls.py file"

cat <<eof
from django.urls import path
from . import views

urlpatterns = [
path(, views.post_list, name=post_list),
]

eof

conti

create_app_urls(){
cat <<eof

from django.urls import path
from . import views

urlpatterns = [
path('', views.post_list, name='post_list'),
]

eof
}>>$name_of_app/urls.py

create_app_urls



# app/views.py
echo "create $name_of_app/views.py"

conti

create_app_views(){
cat <<eof

from django.shortcuts import render
from django.utils import timezone
from .models import Post

def post_list(request):
#   posts = Post.objects.filter(published_date__lte=timezone.now()).order_by('published_date')
#   have to work on my django orm skills
    posts = Post.objects.all()

eof

echo "    return render(request, '$name_of_app/post_list.html', {'posts': posts})"

}>$name_of_app/views.py #overwrite, not append

create_app_views



echo " now to create the html index file"
conti

mkdir -p $name_of_app/templates/$name_of_app/
# blog/templates/blog/post_list.html

create_index_html(){
cat <<eof

<html>
<body>
<p>Hi there!</p>
<p>It works!</p>
</body>
</html>

eof
}>>$name_of_app/templates/$name_of_app/post_list.html

echo "restart the server and checkout the webpage"

conti


echo "fix the $name_of_app/views.py"
conti

fix_app_views2(){
cat <<eof

from django.shortcuts import render
from django.utils import timezone
from .models import Post

def post_list(request):
#   posts = Post.objects.filter(published_date__lte=timezone.now()).order_by('published_date')
#   have to work on my django orm skills
    posts = Post.objects.all()

eof

echo "    return render(request, '$name_of_app/post_list.html', {'posts': posts})"

}>$name_of_app/views.py #overwrite, not append
conti


echo "now to rewrite the index html with django pattern thing"

# blog/templates/blog/post_list.html
# this is not the final form, have to attatch css and all those local contents, the url of that is
# the final form would look like the blog of saccha chua, i think, you update it everyday and it is
# sorted by date and all, and you put in additional divs which you put other stuff with permanent links
# or ad spaces on the side or the footer

fix_index_html(){

cat <<eof
 {% load static %}
 <html>
     <head>
         <title>Django Girls blog</title>
         <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css">
         <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap-theme.min.css">
eof
echo "<link rel=\"stylesheet\" href="{% static \'css/$name_of_app.css\' %}">"
cat <<EOF
     </head>
     <body>
         <div>
             <h1><a href="/">Django Girls Blog</a></h1>
         </div>

         {% for post in posts %}
             <div>
                 <p>published: {{ post.published_date }}</p>
                 <h2><a href="">{{ post.title }}</a></h2>
                 <p>{{ post.text|linebreaksbr }}</p>
             </div>
         {% endfor %}
     </body>
 </html>

EOF


}>$name_of_app/templates/$name_of_app/post_list.html

fix_index_html



echo "now to fix the css"

conti

mkdir -p $name_of_app/static/css/

create_css(){
cat <<eof
.page-header {
background-color: #C25100;
margin-top: 0;
padding: 20px 20px 20px 40px;
}

.page-header h1, .page-header h1 a, .page-header h1 a:visited, .page-header h1 a:active {
color: #ffffff;
font-size: 36pt;
text-decoration: none;
}

.content {
margin-left: 40px;
}

h1, h2, h3, h4 {
font-family: Lobster, cursive;
}

.date {
color: #828282;
}

.save {
float: right;
}

.post-form textarea, .post-form input {
width: 100%;
}

.top-menu, .top-menu:hover, .top-menu:visited {
color: #ffffff;
float: right;
font-size: 26pt;
margin-right: 20px;
}

.post {
margin-bottom: 70px;
}

.post h2 a, .post h2 a:visited {
color: #000000;
}

eof
}>>$name_of_app/static/css/$name_of_app.css

create_css

echo "restart server and look at the webpage again"

conti
echo "now i will start the server"
echo "python3 manage.py runserver"
echo "access page at http://localhost:8000"
conti
python3 manage.py runserver 

# there is a lot of redundant stuff in here, you need to clean up

# https://tutorial.djangogirls.org
# copied from https://tutorial.djangogirls.org
