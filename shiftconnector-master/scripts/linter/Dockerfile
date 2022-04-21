FROM ubuntu:20.04
LABEL name="cfn-linter"

RUN apt update && \
    apt upgrade -y && \
    apt install -y python3.8 python3-pip ruby

# not optimal, but to emulate the pipeline
RUN apt install -y jq curl

# AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install

RUN pip3 install --trusted-host pypi.org --trusted-host files.pythonhosted.org cfn-lint --quiet 
RUN echo ":ssl_verify_mode: 0" > ~/.gemrc
RUN gem install cfn-nag --config-file ~/.gemrc
