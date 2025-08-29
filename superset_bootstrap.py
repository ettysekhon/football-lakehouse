# pyright: reportMissingImports=false
from sqlalchemy import select
from superset import app, db
from superset.models.core import Database

with app.app_context():
    sess = db.session
    name = "football"
    uri = "trino://admin@trino:8080/football"
    obj = sess.scalar(select(Database).where(Database.database_name == name))
    if obj:
        if obj.sqlalchemy_uri != uri:
            obj.sqlalchemy_uri = uri
            obj.expose_in_sqllab = True
            sess.commit()
            print("Updated database URI for football.")
        else:
            print("Database football already present with same URI.")
    else:
        sess.add(
            Database(database_name=name, sqlalchemy_uri=uri, expose_in_sqllab=True)
        )
        sess.commit()
        print("Created database football.")
