##Creamos la aplicación my-blog con base de datos en Posgresql
```
rails new my-blog -d=postgresql
cd my-blog
git init
git add .
git commit -m "rails new my-blog postgresql"
bundle
rake db:create
rake db:migrate
git add .
git commit -m "postgresql configuration"
```
### para ingresar al aconsola de Postgresql
```
psql my-blog_development postgres
```

### creando scaffold de Post
```
rails g scaffold post title:string content:text
rake db:migrate
git add .
git commit -m "adding post to the blog"
```
### Generamos el modelo de comment
```
rails g model comment comment:text post:references
rake db:migrate
git add .
git commit -m "adding comments models"
```
### Generamos controller de Comment
```
rails g controller comments create
git add .
git commit -m "we can create comment for the post"
git add .
git commit -m "show comments of the post"
git add .
git commit -m "count comments"
git add .
git commit -m "cascade delete post and comments"
```
### Nos concetamos a GitHub
```
git remote add origin git@github.com:almapase/MyBlog.git
git push origin master
```
## Instalar Devise
### creamos una rama nueva para esto
```
git checkout -b devise
bundle
rails generate devise:install
rails g devise:views
git add .
git commit -m "devise installed an generated"
rails generate devise User
rake db:migrate
git add .
git commit -m "created model and user view to devise"
git add .
git commit -m "navbar  sign in, out and up"
```
###crear una migración: agrega campo name al modelo User
```
rails g migration addNameToUser name:string
rake db:migrate
```
###En el modelo user validamos que el usuario sea requerido:
```
validates :name, presence: true
```
en el registrations/new.html.erb:
```HTML
<div class="field">
  <%= f.label :name %><br />
  <%= f.text_field :name, autofocus: true %>
</div>
```

en /my-blog/app/controllers/application_controller.rb agregamos los Strong parameters para Devise:
```RUBY
before_action :configure_permitted_parameters, if: :devise_controller?

protected
def configure_permitted_parameters
  devise_parameter_sanitizer.for(:sign_up) << :name
  devise_parameter_sanitizer.for(:account_update) << :name
end
```
Para saludar al usuario agregamos en my-blog/app/views/layouts/_ navbar.html.erb:

```HTML
<span>Hola  <%= current_user.name %></span>
```

```
git add .
git commit -m "Create name for the model user"
```

###Relacionando los post y comentarios con los usuarios
creamos migración con referencia:
```
rails g migration addUserIdToPost user:references
rails g migration addUserIdToComment user:references
rake db:migrate
```
Al borrar los usuarios los post y comment se borrarán en cascada
en /my-blog/app/models/user.rb
```RUBY
has_many :posts, :dependent => :destroy
has_many :comments, :dependent => :destroy
```
referencias en Post y comments
en /my-blog/app/models/post.rb:
```RUBY
belongs_to :user
```
en /my-blog/app/models/comment.rb
```RUBY
belongs_to :user
```
```
git add .
git commit -m "add user to comment and  post"
```
##Agregando Moderadores
vamos a implementar un mini sistema de permisos con Devise, dos tipos de usuarios:

>Normal: crea post y comentarios y puede editar o eliminar solo los suyos.
>Editor: crea post y comentarios y puede editar o eliminar todo.

###21) blog - Autorización y Roles con Devise
crear nueva rama:
```
git checkout -b moderadores
```
agregamos el rol de moderador al usuario como integer para ocupar ENUM
```
rails g migration addRoleToUser role:integer
rake db:migrate
```
en /Users/almapase/dlatm-my-blog/my-blog/app/models/user.rb
```RUBY
enum role: [:guest, :moderator]
```
###22) blog - Valores iniciales para el tipo de usuario
en /Users/almapase/dlatm-my-blog/my-blog/app/models/user.rb
```RUBY
before_save :default_values

def default_values
  self.role ||= 0
end
```
###23) blog - Nuestro propio mini sistema de autorización
evitando que un usuario comente o edite sin estar logeado
en: /Users/almapase/dlatm-my-blog/my-blog/app/controllers/posts_controller.rb

```RUBY
# Se solicita autenticacion para todo excepto Index, nuevo y crear
before_action :authenticate_user!, except: [:index, :new, :create]
# Debe ser moderador solo para new y create
before_action :check_moderator!, only: [:new, :create]
....
.
.
.
....
private
# helper para verificar si el user pertenece a rol moderator
def check_moderator!
  authenticate_user!
  unless current_user.moderator?
    redirect_to root_path, alert: "No tienes acceso"
  end
end
```
###24) blog - Introducción a CanCanCan
CanCanCan se preocupa de que el usuario esté logeado y verifica desde el árbol de habilidades si tiene los permisos para manejar el archivo.

en Gemfile:
```RUBY
gem 'cancancan'
```
###25) blog - Arbol de Habilidades
construir arbol de habilidades
se genera el modelo ability.rb
```
rails g cancan:ability
```
en /Users/almapase/dlatm-my-blog/my-blog/app/models/ability.rb
```RUBY
user ||= User.new # para menejar el árbol de habilidades en caso de un usuario no logeado
if user.moderator?
  can :manage, :all
elsif user.guest?
  can :read, :all
  can :create, Post
  can [:edit, :destroy], [Post, Comment], user_id: user.id
else
  can :read, :all
end
```
###26) blog - Testing de Habilidades
en al consola de Rails
```
user = User.first
ability = Ability.new(user)
ability.can?(:edit, Post.new(user:user)) #editar un post de él
ability.can?(:create, Post)
ability.can?(:destroy, Post) #destruir cualquier post
ability.can?(:destroy, Post.new(user: user)) #Destruir su post
```
###27) blog - El Helper Can
Revisar los links a editar y borrar
en my-blog/app/views/posts/index.html.erb
```HTML
<td><%= link_to 'Edit', edit_post_path(post) if can? :edit, post %></td>
<td><%= link_to 'Destroy', post, method: :delete, data: { confirm: 'Are you sure?' } if can? :destroy, post %></td>
```
###28) blog - Lockdown con CanCanCan
Bloqueando los recursos en los controllers de Post y Comment
en:
>my-blog/app/controllers/comments_controller.rb
>my-blog/app/controllers/posts_controller.rb

```RUBY
# esta linea permite a CanCanCan verificar los privilegios de un usuario sobre los recirsos de este controller
load_and_authorize_resource
```
manejando las conexiones no autorizadas
en /my-blog/app/controllers/application_controller.rb
```RUBY
rescue_from CanCan::AccessDenied do |exception|
  redirect_to root_url, :alert => exception.message
end
```
optimización del posts_controller
en /my-blog/app/controllers/posts_controller.rb
eliminaremos las siguientes lineas, por que CanCanCan hace ya esa pega.
```RUBY
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  .
  .
  .

  def set_post
    @post = Post.find(params[:id])
  end
```
###29) blog - Variables de Entorno y protección de claves
Usaremos la Gema dontenv, agregaremos la gema en la parte superior del Gemfile:
```ruby
gem 'dotenv-rails', :groups => [:development, :test]
```
Ahora ejecutamos:
```
$ bundle
```
###30) blog - Recuperando password con Devise


##
31) blog - Subiendo archivos con Carrierwave
32) blog - Guardando al post y al usuario con el comentario
33) blog - Caché en Carrierwave
34) blog - Descargando archivos a través de la URL
35) blog - MiniMagick
36) blog - Fallback al cargar la imágen
37) blog - Relaciones N a N
38) blog - Post Votes y Users
39) blog - Probando las relaciones n a n
40) blog - Creando votos en la consola
##
41) blog - Member vs Collection Vs Resource
42) blog - La acción de votar
43) blog - Guardando los votos
44) blog - Evitando votos repetidos
45) blog - Conteo de votos
46) blog - Cancelando un voto
47) blog - Introducción a polimorfismo
48) blog - Migración e introducción a la interfaz polimórfica
49) blog - Relación Polimórfica entre el usuario y los comentarios
50) blog - Interfaz Votable
##
51) blog - Modificación de la validación de votos
52) blog - Votando Comentarios
53) blog - Mas uno o Menos uno
54) blog - Introducción a los helpers
55) blog - Previniendo conflictos de nombre en los helpers
56) blog - Método Pluralize
57) blog - Intro a Query Strings
58) blog - Buscado Básico
59) blog - Form Tag
60) blog - Búsqueda Parcial
##
61) blog - Búsqueda insensible y multicriterio
62) blog - El archivo Seed
63) blog - Paginación con Kaminari
64) blog - Ajax y negociación de contenido
65) blog - Respond_to y Cors
66) blog - Creando un post por ajax
67) blog - Render de comentario por Ajax
68) blog - Cuenta de votos
69) blog - Mejor cuenta de votos
70) blog - Introducción a Ajax con Jquery
##
71) blog - El método .ajax
72) blog - Búsqueda utilizando .ajax
73) blog - Ajaxeando la páginación
74) blog - Búsqueda a partir de n caracteres
75) blog - Introducción a Infinite Scrolling
76) blog - Alto del viewport y del documento
77) blog - Armando el Infinite Scrolling
78) blog - Evitando multiples llamados con Debounce
79) blog - Optimización y Eager Loading
80) blog - Counter cache
##
81) blog - buscando problemas de n+1 con Bullet
82) blog - Friendly Id
83) blog - Introducción a Amazon S3
84) blog - La gema FOG
85) blog - Configurando fog
86) blog - Estrategias de Hosting
87) blog - Deploy a heroku
88) blog - Heroku rename
89) blog - Comprando el .com
90) blog - Configurando el .com
