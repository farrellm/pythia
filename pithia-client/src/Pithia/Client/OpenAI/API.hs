{-# LANGUAGE DeriveGeneric #-}

module Pithia.Client.OpenAI.API where

import Data.Aeson
  ( FromJSON (parseJSON),
    ToJSON (toEncoding),
    defaultOptions,
    genericParseJSON,
    genericToEncoding,
  )
import Data.Text (Text)
import GHC.Generics (Generic)
import Pithia.Client.Common (jsonOptions)

data ChatRequest = ChatRequest
  { model :: Text,
    messages :: [Message]
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

instance ToJSON ChatRequest where
  toEncoding = genericToEncoding defaultOptions

instance ToJSON Message where
  toEncoding = genericToEncoding defaultOptions

instance ToJSON Role where
  toEncoding = genericToEncoding jsonOptions

instance FromJSON Message

instance FromJSON Role where
  parseJSON = genericParseJSON jsonOptions

instance FromJSON ChatResponse

instance FromJSON Choice
