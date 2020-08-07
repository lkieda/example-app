FROM ruby:2.7-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dumb-init \
        make cmake gcc g++ && \
    apt-get clean

WORKDIR /code

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/code/entrypoint.sh"]

CMD ["bundle",  "exec", "karafka", "worker"]
