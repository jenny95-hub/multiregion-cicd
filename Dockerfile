FROM python:3.9-slim

WORDIR/app

COPY ..

RUN pip install flask pytest

EXPOSE 80

CMD ["python","app/app.py"]