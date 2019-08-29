#lang scribble/manual

@(require (for-label racket/base
                     racket/contract
                     redis)
          "redis.rkt")

@title{@exec{redis}: bindings for Redis}
@author[(author+email "Bogdan Popa" "bogdan@defn.io")]

@section[#:tag "intro"]{Introduction}

This package provides up-to-date bindings to the Redis database.

@section[#:tag "reference"]{Reference}
@defmodule[redis]

@subsection[#:tag "client"]{The Client}

Each client represents a single TCP connection to the Redis server.

@defproc[(make-redis [#:client-name client-name string? "racket-redis"]
                     [#:host host string? "127.0.0.1"]
                     [#:port port (integer-in 0 65535) 6379]
                     [#:timeout timeout (and/c rational? positive?) 5]
                     [#:db db (integer-in 0 16) 0]) redis?]{

  Creates a redis client and immediately attempts to connect to the
  database at @racket[host] and @racket[port].

  The @racket[timeout] parameter controls the maximum amount of time
  the client will wait for any given response from the database.
}

@defproc[(redis? [v any/c]) boolean?]{
  Returns @racket[#t] when @racket[v] is a Redis client.
}

@defproc[(redis-connected? [client redis?]) boolean?]{
  Returns @racket[#t] when @racket[client] appears to be connected to
  the database.  Does not detect broken pipes.
}

@defproc[(redis-connect! [client redis?]) void?]{
  Initiales a connection to the database.  If one is already open,
  then the client is first disconnected before the new connection is
  made.
}

@defproc[(redis-disconnect! [client redis?]) void?]{
  Disconnects from the server immediately and without sending a
  @exec{QUIT} command.  Does nothing if the client is already
  disconnected.
}

@defparam[redis-null value any/c #:value 'null]{
  The parameter that holds the value that represents "null" values
  from Redis.
}

@defproc[(redis-null? [v any/c]) boolean?]{
  Returns @racket[#t] if @racket[v] is @racket[equal?] to
  @racket[(redis-null)].
}

@subsection[#:tag "commands"]{Supported Commands}

@defcmd[(append! [key string?] [value string?]) exact-nonnegative-integer?]{
  @exec{APPEND}s @racket[value] to @racket[key] if it exists and
  returns the new length of @racket[key].
}

@defcmd[(auth! [password string?]) string?]{
  @exec{AUTH}s the current connection using @racket[password].  Raises
  an exception if authentication is not set up.
}

@defcmd[(bg-rewrite-aof!) #t]{
  Initiates a @exec{BGREWRITEAOF}.
}

@defcmd[(bg-save!) #t]{
  Initiates a @exec{BGSAVE}.
}

@defcmd[(bitcount [key string?]
                  [#:start start exact-integer? 0]
                  [#:end end exact-integer? -1]) exact-nonnegative-integer?]{
  Counts the bits in @racket[key] between racket[start] and
  @racket[end].
}

@defcmd[(client-id) exact-integer?]{
  Returns the current client id.
}

@defcmd[(client-name) string?]{
  Returns the current client name.
}

@defcmd[(set-client-name! [name string?]) boolean?]{
  Sets the current client name on the server.
}

@defcmd[(count) exact-integer?]{
  Returns the number of keys in the database, like @exec{DBSIZE}.
}

@defcmd[(decr! [key string?] [n exact-integer? 1]) exact-integer?]{
  Decrements @racket[key] by @racket[n].  If @racket[n] is @racket[1],
  then an @racket{DECR} is issued.  Otherwise, an @racket{DECRBY} is
  issued.
}

@defcmd[(remove! [key string?] ...+) exact-nonnegative-integer?]{
  Removes each @racket[key] from the database and returns the number
  of keys that were removed.
}

@defcmd[(echo [message string?]) string?]{
  Returns @racket[message].
}

@defcmd[(has-key? [key string?]) boolean?]{
  Returns @racket[#t] if @racket[key] is in the database.  Uses
  @exec{EXISTS} under the hood.
}

@defcmd[(count-keys [key string?] ...) exact-nonnegative-integer?]{
  Returns how many of the given @racket[key]s exist.  Keys are counted
  as many times as they are provided.  Analogous to @exec{EXISTS}.
}

@defcmd[(flush-all!) #t]{
  Deletes everything in all the databases.
}

@defcmd[(flush-db!) #t]{
  Deletes everything in the current database.
}

@defcmd[(ref [key string?] ...+) any/c]{
  If called with a single key, then it is analogous to a @exec{GET}.
  Otherwise, it issues an @exec{MGET}.
}

@defcmd[(incr! [key string?] [n (or/c exact-integer? rational?)]) (or/c string? exact-integer?)]{
  If @racket[n] is @racket[1], then an @exec{INCR} is issued.  If
  @racket[n] is an @racket[exact-integer?] then an @exec{INCRBY} is
  issued.  Otherwise,  an @exec{INCRBYFLOAT} is issued.
}

@defcmd[(persist! [key string?]) boolean?]{
  Removes @racket[key]'s expiration, if any.
}

@defcmd[(expire-in! [key string?] [ms exact-nonnegative-integer?]) boolean?]{
  Marks @racket[key] so that it will expire in @racket[ms]
  milliseconds.  Returns @racket[#f] if the key is not in the
  database.

  Issues a @exec{PEXPIRE}.
}

@defcmd[(expire-at! [key string?] [ms exact-nonnegative-integer?]) boolean?]{
  Marks @racket[key] so that it will expire at the UNIX timestamp
  represented by @racket[ms] milliseconds.  Returns @racket[#f] if the
  key is not in the database.

  Issues a @exec{PEXPIREAT}.
}

@defcmd[(ttl [key string?]) (or/c 'missing 'persisted exact-nonnegative-integer?)]{
  Returns the number of milliseconds before @racket[key] expires.

  If @racket[key] is not present on the server, then @racket['missing]
  is returned.

  If @racket[key] exists but isn't marked for expiration, then
  @racket['persisted] is returned.
}

@defcmd[(ping) string?]{
  Pings the server and returns @racket["PONG"].
}

@defcmd[(quit!) void?]{
  Gracefully disconnects from the server.
}

@defcmd[(random-key) (or/c redis-null? string?)]{
  Returns a random key from the database or @racket[(redis-null)].
}

@defcmd[(rename! [src string?]
                 [dest string?]
                 [#:unless-exists? unless-exists? boolean? #f]) boolean?]{

  Renames @racket[src] to @racket[dest].

  If @racket[unless-exists?] is @racket[#t], then the key is only
  renamed if a key named @racket[dest] does not already exist.
}

@defcmd[(select! [db (integer-in 0 16)]) boolean?]{
  Selects the current database.
}

@defcmd[(set! [key string?]
              [value string?]
              [#:expires-in expires-in (or/c false/c exact-nonnegative-integer?) #f]
              [#:unless-exists? unless-exists? boolean? #f]
              [#:when-exists? when-exists? boolean? #f]) boolean?]{

  Sets @racket[key] to @racket[value].

  If @racket[expires-in] is @racket[#t], then the key will expire
  after @racket[expires-in] milliseconds.

  If @racket[unless-exists?] is @racket[#t], then the key will only be
  set if it doesn't already exist.

  If @racket[when-exists?] is @racket[#t], then the key will only be
  set if it already exists.
}

@defcmd[(touch! [key string?] ...+) exact-nonnegative-integer?]{
  Updates the last modification time for each @racket[key] and returns
  the number of keys that were updated.
}

@defcmd[(type [key string?]) (or/c 'none 'string 'list 'set 'zset 'hash 'stream)]{
  Returns @racket[key]'s type.
}