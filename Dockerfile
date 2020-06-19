FROM ubuntu:16.04

RUN apt-get update \
    && apt-get install sudo -y \
    && apt-get install curl -y \
    && apt-get install unzip -y \
    && apt-get install jq -y

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install

RUN mkdir myscript

WORKDIR myscript

RUN echo '#!/bin/bash' >> start.sh \
    && echo "aws s3 cp s3://your-s3-bucket-where-the-script-is . --recursive" >> start.sh \
    && echo "chmod +x run.sh" >> start.sh\
    && echo "./run.sh" >> start.sh

RUN sed -i 's/\r$//' start.sh

RUN chmod +x start.sh

CMD ["/bin/bash","start.sh"]
