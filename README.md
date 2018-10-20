# sit_eiffel

Mi idea is to create a pattern which permits me to handle REST WEB Services with DB Entities with typical has_and_belongs_to_many pattern. Mi idea is to have the most generic classes to be able to apply the model to the other entities I'll have. So in a few words,

    I have DB_ENTITY which has an ID and direct entities which are descendent and have the fields like name, etc...
    A DB_SERVICE which does the generic requests for each object and DB CRUD(Create,Read,Update,Delete) any object of my system could inherit from it and add some particular fonctionalities
    A SIT_HANDLER which is the request handler which will do the get/post/put/delete with again the entities handlers which will handle the particularities of each entity

Into SIT_HANDLER->set_handler you'll find the case I'd like to deal with setting the URL of handler to /DB_ENTITY/child_entity_name/{id} to get all child entities from a particular one (typical has_many case)

More than that, I'd like to add something such as this question with CHILD_DB_ENTITY and PARENT_DB_ENTITY

I'm really open to other designs, the one I'm trying to implement seems for me the most generic one still separating entities,services,url_handlers, hoping to get a design which makes me able to define the less things possible into the descendants (COMPANY, BRANCH, SECTOR, etc.).

Many thx for your patience and expertise sharing!

