ARG VERSION=latest
FROM node:${VERSION}

# prerequis
RUN set -eux; \
    apt-get update -y; \
	apt-get install -y --no-install-recommends gzip tar curl usbutils sudo vim openjdk-8-jdk; \
	rm -rf /var/lib/apt/lists/*

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $JAVA_HOME/bin:$PATH

# https://jdk.java.net/
ENV JAVA_VERSION 12.0.1
ENV JAVA_URL https://download.java.net/java/GA/jdk12.0.1/69cfe15208a647278a19ef0990eea691/12/GPL/openjdk-12.0.1_linux-x64_bin.tar.gz
ENV JAVA_SHA256 151eb4ec00f82e5e951126f572dc9116104c884d97f91be14ec11e85fc2dd626

# RUN set -eux; \
# 	\
RUN curl -fL -o /openjdk.tgz "$JAVA_URL";
RUN echo "$JAVA_SHA256 /openjdk.tgz" | sha256sum -c -;
RUN mkdir -p "$JAVA_HOME" "/usr/lib/jvm/openjdk-12.0.1";
RUN tar --extract --file /openjdk.tgz --directory "/usr/lib/jvm/openjdk-12.0.1" --strip-components 1;
RUN rm /openjdk.tgz;

RUN for bin in "/usr/lib/jvm/java-8-openjdk-amd64"*; do \
		base="$(basename "$bin")"; \
		[ ! -e "/usr/bin/$base" ]; \
        update-alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; \
	done;

# https://github.com/docker-library/openjdk/issues/212#issuecomment-420979840
# https://openjdk.java.net/jeps/341
RUN java -Xshare:dump;

VOLUME ["/app","/dist"]

COPY command.sh /command.sh
RUN chmod +x /command.sh

RUN userdel node && \
    groupadd -g 1000 nativescript && \
    useradd -ms /bin/bash nativescript -u 1000 -g 1000

# naative script
RUN npm install -g nativescript --unsafe-perm; tns error-reporting disable

# Android SDK
ARG ANDROID_SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip"
RUN curl -o /tmp/android-sdk.zip $ANDROID_SDK_URL
RUN mkdir -p /opt/android-sdk /app /dist && \
    chown nativescript:nativescript /tmp/android-sdk.zip /opt/android-sdk /app /dist

RUN echo "nativescript     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER nativescript

ENV ANDROID_HOME /opt/android-sdk
RUN tns error-reporting disable && \
    unzip -q /tmp/android-sdk.zip -d /opt/android-sdk && \
    rm /tmp/android-sdk.zip

RUN echo "y" | "$ANDROID_HOME"/tools/bin/sdkmanager "build-tools;29.0.0" "build-tools;28.0.0" "platforms;android-28" "platforms;android-29" "extras;android;m2repository" "extras;google;m2repository"
RUN echo "y" | "$ANDROID_HOME"/tools/bin/sdkmanager "platform-tools"
RUN echo "y" | "$ANDROID_HOME"/tools/bin/sdkmanager --update

ENV PATH $PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/extras

WORKDIR /app

CMD ["/command.sh"]