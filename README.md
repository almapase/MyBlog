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
Para saludar al usuario agregamos en my-blog/app/views/layouts/_navbar.html.erb:

```RUBY
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
###Agregando Moderadores
