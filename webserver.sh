#! /bin/bash

# taken from https://ruslanspivak.com
# https://ruslanspivak.com/lsbaws-part1/

var=0

# first we generate some files
echo "Generating a set of files in the current directory"
echo "if file already present then nothing will happen"
echo "press return to continue"
read junk

webserver1(){
cat <<EOF
import socket

HOST, PORT = '', 8888

listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
listen_socket.bind((HOST, PORT))
listen_socket.listen(1)
print 'Serving HTTP on port %s ...' % PORT
while True:
    client_connection, client_address = listen_socket.accept()
    request = client_connection.recv(1024)
    print request

    http_response = """\
HTTP/1.1 200 OK

Hello, World!
 """
    client_connection.sendall(http_response)
    client_connection.close()
EOF
}>>webserver1.py

if [ -e webserver1.py ]
then
    :
else    
    webserver1
fi

webserver2(){
cat <<EOF

# Tested with Python 2.7.9, Linux & Mac OS X
import socket
import StringIO
import sys

class WSGIServer(object):
    address_family = socket.AF_INET
    socket_type = socket.SOCK_STREAM
    request_queue_size = 1

    def __init__(self, server_address):
        # Create a listening socket
        self.listen_socket = listen_socket = socket.socket(
            self.address_family,
            self.socket_type
        )
        # Allow to reuse the same address
        listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        # Bind
        listen_socket.bind(server_address)
        # Activate
        listen_socket.listen(self.request_queue_size)
        # Get server host name and port
        host, port = self.listen_socket.getsockname()[:2]
        self.server_name = socket.getfqdn(host)
        self.server_port = port
        # Return headers set by Web framework/Web application
        self.headers_set = []

    def set_app(self, application):
        self.application = application

    def serve_forever(self):
        listen_socket = self.listen_socket
        while True:
            # New client connection
            self.client_connection, client_address = listen_socket.accept()
            # Handle one request and close the client connection. Then
            # loop over to wait for another client connection
            self.handle_one_request()

    def handle_one_request(self):
        self.request_data = request_data = self.client_connection.recv(1024)
        # Print formatted request data a la 'curl -v'
        print(''.join(
            '< {line}\n'.format(line=line)
            for line in request_data.splitlines()
        ))

        self.parse_request(request_data)

        # Construct environment dictionary using request data
        env = self.get_environ()

        # It's time to call our application callable and get
        # back a result that will become HTTP response body
        result = self.application(env, self.start_response)

        # Construct a response and send it back to the client
        self.finish_response(result)

    def parse_request(self, text):
        request_line = text.splitlines()[0]
        request_line = request_line.rstrip('\r\n')
        # Break down the request line into components
        (self.request_method,  # GET
         self.path,            # /hello
         self.request_version  # HTTP/1.1
         ) = request_line.split()

    def get_environ(self):
        env = {}
        # The following code snippet does not follow PEP8 conventions
        # but it's formatted the way it is for demonstration purposes
        # to emphasize the required variables and their values
        #
        # Required WSGI variables
        env['wsgi.version']      = (1, 0)
        env['wsgi.url_scheme']   = 'http'
        env['wsgi.input']        = StringIO.StringIO(self.request_data)
        env['wsgi.errors']       = sys.stderr
        env['wsgi.multithread']  = False
        env['wsgi.multiprocess'] = False
        env['wsgi.run_once']     = False
        # Required CGI variables
        env['REQUEST_METHOD']    = self.request_method    # GET
        env['PATH_INFO']         = self.path              # /hello
        env['SERVER_NAME']       = self.server_name       # localhost
        env['SERVER_PORT']       = str(self.server_port)  # 8888
        return env

    def start_response(self, status, response_headers, exc_info=None):
        # Add necessary server headers
        server_headers = [
            ('Date', 'Tue, 31 Mar 2015 12:54:48 GMT'),
            ('Server', 'WSGIServer 0.2'),
        ]
        self.headers_set = [status, response_headers + server_headers]
        # To adhere to WSGI specification the start_response must return
        # a 'write' callable. We simplicity's sake we'll ignore that detail
        # for now.
        # return self.finish_response

    def finish_response(self, result):
        try:
            status, response_headers = self.headers_set
            response = 'HTTP/1.1 {status}\r\n'.format(status=status)
            for header in response_headers:
                response += '{0}: {1}\r\n'.format(*header)
            response += '\r\n'
            for data in result:
                response += data
            # Print formatted response data a la 'curl -v'
            print(''.join(
                '> {line}\n'.format(line=line)
                for line in response.splitlines()
            ))
            self.client_connection.sendall(response)
        finally:
            self.client_connection.close()


SERVER_ADDRESS = (HOST, PORT) = '', 8888


def make_server(server_address, application):
    server = WSGIServer(server_address)
    server.set_app(application)
    return server


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit('Provide a WSGI application object as module:callable')
    app_path = sys.argv[1]
    module, application = app_path.split(':')
    module = __import__(module)
    application = getattr(module, application)
    httpd = make_server(SERVER_ADDRESS, application)
    print('WSGIServer: Serving HTTP on port {port} ...\n'.format(port=PORT))
    httpd.serve_forever()

EOF
}>>webserver2.py

if [ -e webserver2.py ]
then
    :
else    
    webserver2
fi

pyramid_web_application(){
cat <<EOF

from pyramid.config import Configurator
from pyramid.response import Response


def hello_world(request):
    return Response(
        'Hello world from Pyramid!\n',
        content_type='text/plain',
    )

config = Configurator()
config.add_route('hello', '/hello')
config.add_view(hello_world, route_name='hello')
app = config.make_wsgi_app()


EOF
}>>pyramid_app.py

if [ -e pyramid_app.py ]
then
    :
else    
    pyramid_web_application
fi

flask_web_application(){
cat <<EOF
from flask import Flask
from flask import Response
flask_app = Flask('flaskapp')


@flask_app.route('/hello')
def hello_world():
    return Response(
        'Hello world from Flask!\n',
        mimetype='text/plain'
    )

app = flask_app.wsgi_app

EOF
}>>flask_app.py

if [ -e flask_app.py ]
then
    :
else    
    flask_web_application
fi

django_web_application(){
cat <<EOF
import sys
sys.path.insert(0, './helloworld')
from helloworld import wsgi


app = wsgi.application

EOF

}>>django_app.py

if [ -e django_app.py ]
then
    :
else    
    django_web_application
fi

unknown_server_program(){
cat <<EOF
def run_application(application):
    """Server code."""
    # This is where an application/framework stores
    # an HTTP status and HTTP response headers for the server
    # to transmit to the client
    headers_set = []
    # Environment dictionary with WSGI/CGI variables
    environ = {}

    def start_response(status, response_headers, exc_info=None):
        headers_set[:] = [status, response_headers]

    # Server invokes the application' callable and gets back the
    # response body
    result = application(environ, start_response)
    # Server builds an HTTP response and transmits it to the client
     

def app(environ, start_response):
    """A barebones WSGI app."""
    start_response('200 OK', [('Content-Type', 'text/plain')])
    return ['Hello world!']

run_application(app)

EOF

}

# unknown_server_program


minimal_wsgi_web_application(){
cat <<EOF
def app(environ, start_response):
    """A barebones WSGI application.
    This is a starting point for your own Web framework :)
    """
    status = '200 OK'
    response_headers = [('Content-Type', 'text/plain')]
    start_response(status, response_headers)
    return ['Hello world from a simple WSGI application!\n']

EOF
}>>minimal_wsgiapp.py

if [ -e mininal_wsgiapp.py ] # it would have been better to put all of these into a list and iterate with this function
then
    :
else    
    minimal_wsgi_web_application
fi

webserver3a(){
cat <<EOF

 #####################################################################
 # Iterative server - webserver3a.py                                 #
 #                                                                   #
 # Tested with Python 2.7.9 & Python 3.4 on Ubuntu 14.04 & Mac OS X  #
 #####################################################################
import socket

SERVER_ADDRESS = (HOST, PORT) = '', 8888
REQUEST_QUEUE_SIZE = 5


def handle_request(client_connection):
    request = client_connection.recv(1024)
    print(request.decode())
    http_response = b"""\
HTTP/1.1 200 OK

Hello, World!
"""
    client_connection.sendall(http_response)


def serve_forever():
    listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listen_socket.bind(SERVER_ADDRESS)
    listen_socket.listen(REQUEST_QUEUE_SIZE)
    print('Serving HTTP on port {port} ...'.format(port=PORT))

    while True:
        client_connection, client_address = listen_socket.accept()
        handle_request(client_connection)
        client_connection.close()

if __name__ == '__main__':
    serve_forever()

EOF
}>>webserver3a.py

if [ -e webserver3a.py ]
then
    :
else    
    webserver3a
fi

webserver3b(){

cat <<EOF
 #########################################################################
 # Iterative server - webserver3b.py                                     #
 #                                                                       #
 # Tested with Python 2.7.9 & Python 3.4 on Ubuntu 14.04 & Mac OS X      #
 #                                                                       #
 # - Server sleeps for 60 seconds after sending a response to a client   #
 #########################################################################
import socket
import time

SERVER_ADDRESS = (HOST, PORT) = '', 8888
REQUEST_QUEUE_SIZE = 5


def handle_request(client_connection):
    request = client_connection.recv(1024)
    print(request.decode())
    http_response = b"""\
HTTP/1.1 200 OK

Hello, World!
"""
    client_connection.sendall(http_response)
    time.sleep(60)  # sleep and block the process for 60 seconds

def serve_forever():
    listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listen_socket.bind(SERVER_ADDRESS)
    listen_socket.listen(REQUEST_QUEUE_SIZE)
    print('Serving HTTP on port {port} ...'.format(port=PORT))

    while True:
        client_connection, client_address = listen_socket.accept()
        handle_request(client_connection)
        client_connection.close()

if __name__ == '__main__':
    serve_forever()

EOF
}>>webserver3b.py

if [ -e webserver3b.py ]
then
    :
else    
    webserver3b
fi

webserver3c(){
cat <<EOF

 ###########################################################################
 # Concurrent server - webserver3c.py                                      #
 #                                                                         #
 # Tested with Python 2.7.9 & Python 3.4 on Ubuntu 14.04 & Mac OS X        #
 #                                                                         #
 # - Child process sleeps for 60 seconds after handling a client's request #
 # - Parent and child processes close duplicate descriptors                #
 #                                                                         #
 ###########################################################################
import os
import socket
import time

SERVER_ADDRESS = (HOST, PORT) = '', 8888
REQUEST_QUEUE_SIZE = 5


def handle_request(client_connection):
    request = client_connection.recv(1024)
    print(
        'Child PID: {pid}. Parent PID {ppid}'.format(
            pid=os.getpid(),
            ppid=os.getppid(),
        )
    )
    print(request.decode())
    http_response = b"""\
HTTP/1.1 200 OK

Hello, World!
"""
    client_connection.sendall(http_response)
    time.sleep(60)


def serve_forever():
    listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listen_socket.bind(SERVER_ADDRESS)
    listen_socket.listen(REQUEST_QUEUE_SIZE)
    print('Serving HTTP on port {port} ...'.format(port=PORT))
    print('Parent PID (PPID): {pid}\n'.format(pid=os.getpid()))

    while True:
        client_connection, client_address = listen_socket.accept()
        pid = os.fork()
        if pid == 0:  # child
            listen_socket.close()  # close child copy
            handle_request(client_connection)
            client_connection.close()
            os._exit(0)  # child exits here
        else:  # parent
            client_connection.close()  # close parent copy and loop over

if __name__ == '__main__':
    serve_forever()

EOF
}>>webserver3c.py

if [ -e webserver3c.py ]
then
    :
else 
    webserver3c
fi

webserver3d(){
cat <<EOF

 ###########################################################################
 # Concurrent server - webserver3d.py                                      #
 #                                                                         #
 # Tested with Python 2.7.9 & Python 3.4 on Ubuntu 14.04 & Mac OS X        #
 ###########################################################################

import os
import socket

SERVER_ADDRESS = (HOST, PORT) = '', 8888
REQUEST_QUEUE_SIZE = 5


def handle_request(client_connection):
    request = client_connection.recv(1024)
    http_response = b"""\
HTTP/1.1 200 OK

Hello, World!
"""
    client_connection.sendall(http_response)


def serve_forever():
    listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listen_socket.bind(SERVER_ADDRESS)
    listen_socket.listen(REQUEST_QUEUE_SIZE)
    print('Serving HTTP on port {port} ...'.format(port=PORT))

    clients = []
    while True:
        client_connection, client_address = listen_socket.accept()
        # store the reference otherwise it's garbage collected
        # on the next loop run
        clients.append(client_connection)
        pid = os.fork()
        if pid == 0:  # child
            listen_socket.close()  # close child copy
            handle_request(client_connection)
            client_connection.close()
            os._exit(0)  # child exits here
        else:  # parent
            # client_connection.close()
            print(len(clients))

if __name__ == '__main__':
    serve_forever()

EOF
}>>webserver3d.py

if [ -e webserver3d.py ]
then
    :
else   
 webserver3d
fi

client3(){

    cat <<EOF EOF


    #####################################################################
 # Test client - client3.py                                          #
 #                                                                   #
 # Tested with Python 2.7.9 & Python 3.4 on Ubuntu 14.04 & Mac OS X  #
 #####################################################################
import argparse
import errno
import os
import socket


SERVER_ADDRESS = 'localhost', 8888
REQUEST = b"""\
GET /hello HTTP/1.1
Host: localhost:8888

"""


def main(max_clients, max_conns):
    socks = []
    for client_num in range(max_clients):
        pid = os.fork()
        if pid == 0:
            for connection_num in range(max_conns):
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.connect(SERVER_ADDRESS)
                sock.sendall(REQUEST)
                socks.append(sock)
                print(connection_num)
                os._exit(0)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Test client for LSBAWS.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        '--max-conns',
        type=int,
        default=1024,
        help='Maximum number of connections per client.'
    )
    parser.add_argument(
        '--max-clients',
        type=int,
        default=1,
        help='Maximum number of clients.'
    )
    args = parser.parse_args()
    main(args.max_clients, args.max_conns)

EOF
}>>client3.py


if [ -e client3.py ]
then
    :
else   
 client3
fi




webserver3e(){
cat <<EOF
 ###########################################################################
 # Concurrent server - webserver3e.py                                      #
 #                                                                         #
 # Tested with Python 2.7.9 & Python 3.4 on Ubuntu 14.04 & Mac OS X        #
 ###########################################################################
import os
import signal
import socket
import time

SERVER_ADDRESS = (HOST, PORT) = '', 8888
REQUEST_QUEUE_SIZE = 5


def grim_reaper(signum, frame):
    pid, status = os.wait()
    print(
        'Child {pid} terminated with status {status}'
        '\n'.format(pid=pid, status=status)
    )


def handle_request(client_connection):
    request = client_connection.recv(1024)
    print(request.decode())
    http_response = b"""\
HTTP/1.1 200 OK

Hello, World!
"""
    client_connection.sendall(http_response)
    # sleep to allow the parent to loop over to 'accept' and block there
    time.sleep(3)


def serve_forever():
    listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listen_socket.bind(SERVER_ADDRESS)
    listen_socket.listen(REQUEST_QUEUE_SIZE)
    print('Serving HTTP on port {port} ...'.format(port=PORT))

    signal.signal(signal.SIGCHLD, grim_reaper)

    while True:
        client_connection, client_address = listen_socket.accept()
        pid = os.fork()
        if pid == 0:  # child
            listen_socket.close()  # close child copy
            handle_request(client_connection)
            client_connection.close()
            os._exit(0)
        else:  # parent
            client_connection.close()

if __name__ == '__main__':
    serve_forever()

EOF
}>>webserver3e.py

if [ -e webserver3e.py ]
then
    :
else  
    webserver3e
fi

webserver3f(){
cat <<EOF
 ###########################################################################
 # Concurrent server - webserver3f.py                                      #
 #                                                                         #
 # Tested with Python 2.7.9 & Python 3.4 on Ubuntu 14.04 & Mac OS X        #
 ###########################################################################
import errno
import os
import signal
import socket

SERVER_ADDRESS = (HOST, PORT) = '', 8888
REQUEST_QUEUE_SIZE = 1024


def grim_reaper(signum, frame):
    pid, status = os.wait()


def handle_request(client_connection):
    request = client_connection.recv(1024)
    print(request.decode())
    http_response = b"""\
HTTP/1.1 200 OK
 Hello, World!
"""
    client_connection.sendall(http_response)


def serve_forever():
    listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listen_socket.bind(SERVER_ADDRESS)
    listen_socket.listen(REQUEST_QUEUE_SIZE)
    print('Serving HTTP on port {port} ...'.format(port=PORT))

    signal.signal(signal.SIGCHLD, grim_reaper)

    while True:
        try:
            client_connection, client_address = listen_socket.accept()
        except IOError as e:
            code, msg = e.args
            # restart 'accept' if it was interrupted
            if code == errno.EINTR:
                continue
            else:
                raise

        pid = os.fork()
        if pid == 0:  # child
            listen_socket.close()  # close child copy
            handle_request(client_connection)
            client_connection.close()
            os._exit(0)
        else:  # parent
            client_connection.close()  # close parent copy and loop over


if __name__ == '__main__':
    serve_forever()

EOF
}>>webserver3f.py

if [ -e webserver3f ]
then
    :
else
    webserver3f
fi

webserver3g(){
cat <<EOF

 ###########################################################################
 # Concurrent server - webserver3g.py                                      #
 #                                                                         #
 # Tested with Python 2.7.9 & Python 3.4 on Ubuntu 14.04 & Mac OS X        #
 ###########################################################################
import errno
import os
import signal
import socket

SERVER_ADDRESS = (HOST, PORT) = '', 8888
REQUEST_QUEUE_SIZE = 1024


def grim_reaper(signum, frame):
    while True:
        try:
            pid, status = os.waitpid(
                -1,          # Wait for any child process
                 os.WNOHANG  # Do not block and return EWOULDBLOCK error
            )
        except OSError:
            return

        if pid == 0:  # no more zombies
            return


def handle_request(client_connection):
    request = client_connection.recv(1024)
    print(request.decode())
    http_response = b"""\
HTTP/1.1 200 OK

Hello, World!
"""
    client_connection.sendall(http_response)


def serve_forever():
    listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listen_socket.bind(SERVER_ADDRESS)
    listen_socket.listen(REQUEST_QUEUE_SIZE)
    print('Serving HTTP on port {port} ...'.format(port=PORT))

    signal.signal(signal.SIGCHLD, grim_reaper)

    while True:
        try:
            client_connection, client_address = listen_socket.accept()
        except IOError as e:
            code, msg = e.args
            # restart 'accept' if it was interrupted
            if code == errno.EINTR:
                continue
            else:
                raise

        pid = os.fork()
        if pid == 0:  # child
            listen_socket.close()  # close child copy
            handle_request(client_connection)
            client_connection.close()
            os._exit(0)
        else:  # parent
            client_connection.close()  # close parent copy and loop over

if __name__ == '__main__':
    serve_forever()

EOF
}>>webserver3g.py

if [ -e webserver3g.py ]
then
    :
else  
    webserver3g
fi

# there would be two files, one runs the many servers and one would run the many clients

access_webserver(){
telnet localhost 8888
firefox http://localhost:8888/hello
curl -v http://localhost:8888/hello

}


install_stuff(){
# sudo pip install virtualenv
mkdir ~/envs
virtualenv ~/envs/lsbaws/
cd ~/envs/lsbaws/

source ./bin/activate
pip install pyramid
pip install flask
pip install django

}

cat_file1(){

if [ -z $file1 ]
then
    :
else
cat $file1
fi
}


what_do_you_want_to_do(){
clear
echo "what do you want to do?"

# menu to select option
#selection_menu(){

cat <<EOF

| webserver1.py                     | A | # menu1 to run the server    |
| webserver2.py                     | B | # menu2 to see the source??? |
| webserver2.py flask_app:app       | C |                              |
| webserver2.py pyramid_app:app     | D |                              |
| webserver2.py django_app:app      | E |                              |
| webserver2.py minimal_wsgiapp:app | F |                              |
| webserver3a.py                    | G |                              |
| webserver3b.py                    | H |                              |
| webserver3c.py                    | I |                              |
| webserver3d.py                    | J |                              |
|                                   |   |                              |
# you would run this more than once so put in a test, if file present do not create the file

# after menu selection, you would be given another menu to choose to see the code, to see instructions
# and to run the server or the commands

EOF
#read user_input
read -n 1 user_input # with the -n key you do not have to hit return key

case $user_input in
    [Aa])
	#       Statement(s) to be executed if pattern1 matches	
#	echo $(1:commnd)
#	current_info
    file=webserver1.py
    menu
	;;
    [Bb])
    file=webserver2.py
    menu
	;;
    [Cc])
    file=webserver2.py
    file1=flask_app.py
    menu
	;;
    [Dd])
    file=webserver2.py
    file1=pyramid_app.py
    menu
	;;
    [Ee])
    file=webserver2.py
    file1=django_app.py
    menu
	;;
    [Ff])
    file=webserver2.py
    file1=minimal_wsgiapp.py
    menu
	;;
    [Gg])
    file=webserver3a.py
    menu
	;;
    [Hh])
    file=webserver3b.py
    menu
	;;
    [Ii])
    file=webserver3c.py
    menu
	;;
    [Jj])
    file=webserver3d.py
    menu
	;;
    [Kk])
	modify
	;;
    [Bb])
	modify
	;;
    [Bb])
	modify
	;;
    [Bb])
	modify
	;;

    pattern3)
	#       Statement(s) to be executed if pattern3 matches
	;;
    *)
	#      Default condition to be executed

esac


}


menu(){
clear
echo "############# choose option ##################"
echo "what do you want to do?"
echo "you selected $file and $file1"
echo
cat <<EOF
| view source          | s |
| instructions         | i |
| run program          | r |
| back to main menu    | b |

EOF
# read user_input
read -n 1 user_input # with the -n key you do not have to hit the return key

case $user_input in
    [Ss])
#       Statement(s) to be executed if pattern1 matches	
    cat $file 
    cat_file1 
    echo "press return to go back"
    read junk
    menu
	;;
    [Ii])
# go to a webpage, maybe open in elinks and go to relevant section
	;;
    [Rr])
#
if [ -z $file1 ]
then
python $file $file1:app
else
python $file
fi

	;;
    [Bb])
	# go back to main menu
	what_do_you_want_to_do
	;;
    [Ii])
# go to a webpage, maybe open in elinks and go to relevant section
	;;
    [Ii])
# go to a webpage, maybe open in elinks and go to relevant section
	;;

    # pattern3)
    # 	#       Statement(s) to be executed if pattern3 matches
    # 	;;
    *)
	#      Default condition to be executed
	;;
esac

}

# now everything has been defined
# in bash you have to first define the function before you call it. I have two functions, function a calls function b. that means that function b has to be defined before function a. i also want function b to call function a, which means that function a has to be defined before function b. this brings us to a dilemma, which goes first.
# the solution is to let the whole script loop inside. In the first loop, the value of a variable is zero and hence the functions are not triggered, it loops again and this time it works as the variable is incremented. The first useless run or loop of the script means that all the functions are now defined and in the next loop, we can have a call b and b call a.

main(){
if [var == 0] 
then
    :
else
    var=$(expr $var + 1) # is this right ???????
what_do_you_want_to_do
fi

}

main


# taken from https://ruslanspivak.com
