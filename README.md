# Live demo

http://whc-app.us-west-2.elasticbeanstalk.com/

# Running locally

- Run the Dockerfile

  ```
  docker build -t whs-demo .
  docker run whs-demo
  ```

  and visit http://localhost:8000 in your browser.

- Run the source (for development)

  ```
  python -m venv venv
  . venv/bin/activate
  python -m pip install -r requirements.txt
  DEBUG=1 python app.py
  deactivate
  ```

# Deploying to AWS

- Ensure your shell environnent is configured with the proper AWS environment variables
- Edit `00-vars.tf` and configure the region if necessary. 
- Run

  ```
  terraform apply
  ```
  
  The app will be deployed in an ElasticBeanstalk cluster and the 
  environment URL will be displayed at the end ouf the output.

# Running tests

There are tests for the application under `tests/`. You will need to install the dev
requirements with

```
python -m pip install requirements-dev.txt
```

Then you can run the test suite with

```
pytest tests
```

The integration tests requires a Webdriver to be installed. On 
Fedora you can run

```
dnf install chromedriver
```

If you don't have a webdriver installed, you can use 

```
pytest -k 'not test_meta_description'
```

to skip those tests.
