.PHONY: start start-no-thrift stop status restart logs logs-jupyter logs-thrift test

start:
	./start-lakehouse.sh

start-no-thrift:
	./start-lakehouse.sh WITHOUT_THRIFT

stop:
	./stop-lakehouse.sh

status:
	docker compose ps

restart:
	docker compose down
	docker compose up -d

logs:
	docker compose exec spark bash -lc 'touch /tmp/jupyter.log /tmp/thriftserver.log; tail -n +1 -F /tmp/jupyter.log /tmp/thriftserver.log'

logs-jupyter:
	docker compose exec spark bash -lc 'touch /tmp/jupyter.log; tail -n +1 -F /tmp/jupyter.log'

logs-thrift:
	docker compose exec spark bash -lc 'touch /tmp/thriftserver.log; tail -n +1 -F /tmp/thriftserver.log'

test:
	./test-lakehouse.sh