# base node image
FROM node:lts-alpine as base

# set for base and all layer that inherit from it
ENV NODE_ENV production

# Install necessary packages
RUN apk --no-cache add openssl sqlite

# Create user and set ownership and permissions as required
RUN addgroup student && \
    adduser -D -H -g "student" -G student student && \
    mkdir /cst8918-a01 && \
    chown -R student:student /cst8918-a01


# Install all node_modules, including dev dependencies
FROM base as deps

WORKDIR /cst8918-a01

ADD package.json ./
RUN npm install --include=dev

# Setup production node_modules
FROM base as production-deps

WORKDIR /cst8918-a01

COPY --from=deps /cst8918-a01/node_modules /cst8918-a01/node_modules
ADD package.json ./
RUN npm prune --omit=dev

# Build the app
FROM base as build

WORKDIR /cst8918-a01

COPY --from=deps /cst8918-a01/node_modules /cst8918-a01/node_modules

ADD . .
RUN npm run build

# Finally, build the production image with minimal footprint
FROM base

ENV PORT="8080"
ENV NODE_ENV="production"

WORKDIR /cst8918-a01

COPY --from=production-deps /cst8918-a01/node_modules /cst8918-a01/node_modules

COPY --from=build /cst8918-a01/build /cst8918-a01/build
COPY --from=build /cst8918-a01/public /cst8918-a01/public
COPY --from=build /cst8918-a01/package.json /cst8918-a01/package.json

RUN chown -R student:student /cst8918-a01
USER student
CMD [ "/bin/sh", "-c", "./node_modules/.bin/remix-serve ./build/index.js" ]
