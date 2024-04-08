
#FROM python:2.7
FROM python:3

ADD   . /code
WORKDIR /code

RUN pip install -U pip
RUN pip install -r requirements.txt

CMD ["python", "app.py"]
