{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module Pithia.Client.Anthropic.API where

import Cases (snakify)
import Data.Aeson
  ( FromJSON (parseJSON),
    Options (fieldLabelModifier),
    ToJSON (toEncoding),
    genericParseJSON,
    genericToEncoding,
  )
import Data.Default (Default (def))
import Data.Text (Text)
import GHC.Generics (Generic)
import Pithia.Client.Common (jsonOptions, viaText)
import Pithia.Client.Orphan ()
import Text.PrettyPrint.GenericPretty (Out)

data ChatRequest = ChatRequest
  { model :: Text,
    maxTokens :: Int,
    messages :: [Message]
  }
  deriving (Generic, Show)

instance Default ChatRequest where
  def =
    ChatRequest
      { model = "claude-haiku-4-5",
        maxTokens = 1000,
        messages = []
      }

data Message = Message
  { role :: Role,
    content :: Text
  }
  deriving (Generic, Show)

data Role = User | Assistant
  deriving (Generic, Show)

data ChatResponse = ChatResponse
  { id :: Text,
    content :: [Content],
    model :: Text,
    role :: Role,
    stopReason :: Maybe Text,
    stopSequence :: Maybe Text,
    usage :: Usage
  }
  deriving (Generic, Show)

data Content = Content
  { text :: Text,
    contentType :: Text
  }
  deriving (Generic, Show)

data Usage = Usage
  { inputTokens :: Int,
    outputTokens :: Int
  }
  deriving (Generic, Show)

anthropicOptions :: Options
anthropicOptions =
  jsonOptions
    { fieldLabelModifier = \s -> if s == "contentType" then "type" else viaText snakify s
    }

instance ToJSON ChatRequest where
  toEncoding = genericToEncoding anthropicOptions

instance ToJSON Message where
  toEncoding = genericToEncoding anthropicOptions

instance ToJSON Role where
  toEncoding = genericToEncoding jsonOptions

instance FromJSON Message where
  parseJSON = genericParseJSON anthropicOptions

instance FromJSON Role where
  parseJSON = genericParseJSON jsonOptions

instance FromJSON ChatResponse where
  parseJSON = genericParseJSON anthropicOptions

instance FromJSON Content where
  parseJSON = genericParseJSON anthropicOptions

instance FromJSON Usage where
  parseJSON = genericParseJSON anthropicOptions

instance ToJSON ChatResponse where
  toEncoding = genericToEncoding anthropicOptions

instance ToJSON Content where
  toEncoding = genericToEncoding anthropicOptions

instance ToJSON Usage where
  toEncoding = genericToEncoding anthropicOptions

instance Out Message

instance Out Role

instance Out ChatResponse

instance Out Content

instance Out Usage
