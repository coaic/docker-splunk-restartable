# Copyright 2018 Splunk
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
FROM debian:stretch-slim
LABEL maintainer="support@shelde.com"

ARG SPLUNK_FILENAME
ARG SPLUNK_BUILD_URL
ARG SPLUNK_DEFAULTS_URL

ENV SPLUNK_HOME=/opt/splunk \
    SPLUNK_GROUP=splunk \
    SPLUNK_USER=splunk \
    SPLUNK_ROLE=splunk_standalone \
    SPLUNK_FILENAME=${SPLUNK_FILENAME} \
    SPLUNK_DEFAULTS_URL=${SPLUNK_DEFAULTS_URL} \
    SPLUNK_ANSIBLE_HOME=/opt/ansible \
    DEBIAN_FRONTEND=noninteractive

COPY scripts/install.sh /install.sh
RUN /install.sh && rm -rf /install.sh

# Setup users and download Splunk
RUN groupadd -r ${SPLUNK_GROUP} \
    && useradd -r -m -g ${SPLUNK_GROUP} ${SPLUNK_USER} \
    && usermod -aG sudo ${SPLUNK_USER} \
    && sed -i -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers \
    && echo "Downloading Splunk and validating the checksum at: ${SPLUNK_BUILD_URL}" \
    && wget -qO /tmp/${SPLUNK_FILENAME} ${SPLUNK_BUILD_URL} \
    && wget -qO /tmp/${SPLUNK_FILENAME}.sha512 ${SPLUNK_BUILD_URL}.sha512 \
    && (cd /tmp && sha512sum -c ${SPLUNK_FILENAME}.sha512) \
    && mv /tmp/${SPLUNK_FILENAME} /tmp/splunk.tgz \
    && rm -rf /tmp/${SPLUNK_FILENAME}.sha512

USER ${SPLUNK_USER}
COPY modules/splunk-ansible ${SPLUNK_ANSIBLE_HOME}
COPY [ "scripts/entrypoint.sh", "scripts/checkstate.sh", "scripts/createdefaults.py", "/sbin/" ]

EXPOSE 4001 8000 8065 8088 8089 8191 9887 9997
VOLUME [ "/opt/splunk/etc", "/opt/splunk/var" ]

HEALTHCHECK --interval=30s --timeout=30s --start-period=3m --retries=5 CMD /sbin/checkstate.sh || exit 1

ENTRYPOINT [ "/sbin/entrypoint.sh" ]
CMD [ "start-service" ]
