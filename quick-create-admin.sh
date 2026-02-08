#!/bin/bash
docker exec -i shortdrama-mysql mysql -uroot -prootpassword short_drama < /Users/kis/data/cursor_test/insert-admin.sql
