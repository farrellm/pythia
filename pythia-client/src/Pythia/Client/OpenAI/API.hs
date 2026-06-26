{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module Pythia.Client.OpenAI.API where

import Data.Aeson
  ( FromJSON (parseJSON),
    ToJSON (toEncoding),
    genericParseJSON,
    genericToEncoding,
  )
import Data.Text (Text)
import GHC.Generics (Generic)
import Pythia.Client.Common (jsonOptions)

data ChatRequest = ChatRequest
  { model :: Text,
    messages :: [Message],
    stream :: Maybe Bool
  }
  deriving (Generic, Show)

data Message = Message
  { role :: Role,
    content :: Text
  }
  deriving (Generic, Show)

data Role = System | Developer | User | Assistant | Tool
  deriving (Generic, Show)

data ChatResponse = ChatResponse
  { choices :: [Choice]
  }
  deriving (Generic, Show)

data Choice = Choice
  { message :: Message
  }
  deriving (Generic, Show)

data ChatChunk = ChatChunk
  { id :: Text,
    created :: Int,
    model :: Text,
    serviceTier :: Text,
    systemFingerprint :: Maybe Text,
    choices :: [ChunkChoice],
    obfuscation :: Maybe Text
  }
  deriving (Generic, Show)

data FinishReason = Stop | Length
  deriving (Generic, Show)

data ChunkChoice = ChunkChoice
  { index :: Int,
    delta :: MessageDelta,
    finishReason :: Maybe FinishReason
  }
  deriving (Generic, Show)

data MessageDelta = MessageDelta
  { content :: Maybe Text
  }
  deriving (Generic, Show)

instance ToJSON ChatRequest where
  toEncoding = genericToEncoding jsonOptions

instance ToJSON Message where
  toEncoding = genericToEncoding jsonOptions

instance ToJSON Role where
  toEncoding = genericToEncoding jsonOptions

instance FromJSON Message

instance FromJSON Role where
  parseJSON = genericParseJSON jsonOptions

instance FromJSON ChatResponse

instance ToJSON ChatResponse where
  toEncoding = genericToEncoding jsonOptions

instance ToJSON Choice where
  toEncoding = genericToEncoding jsonOptions

instance FromJSON Choice where
  parseJSON = genericParseJSON jsonOptions

instance FromJSON ChatChunk where
  parseJSON = genericParseJSON jsonOptions

instance FromJSON FinishReason where
  parseJSON = genericParseJSON jsonOptions

instance FromJSON ChunkChoice where
  parseJSON = genericParseJSON jsonOptions

instance FromJSON MessageDelta where
  parseJSON = genericParseJSON jsonOptions
