Chunk = require '../models/server/chunk'
aws = require 'aws-sdk'

getKey = (x, z) -> "#{x}.#{z}.chunk"

module.exports = (options) ->
  aws.config.update options.awsOptions

  s3 = new aws.S3(options.awsOptions).client
  s3.createBucket {Bucket: options.bucket}

  get: (x, z, cb) ->
    params =
      Bucket: options.bucket
      Key: getKey x, z
    s3.getObject params, (err, data) ->
      chunk = new Chunk data.Body if data
      cb null, chunk

  set: (chunk, x, z, cb) ->
    params =
      Bucket: options.bucket
      Key: getKey x, z
      Body:  chunk.buf
    s3.putObject params, cb

