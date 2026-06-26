{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE MultiWayIf #-}
{-# LANGUAGE OverloadedStrings #-}

module Pythia.Client.Anthropic.API where

import Cases (snakify)
import Data.Aeson
  ( FromJSON (parseJSON),
    Options (constructorTagModifier, fieldLabelModifier, sumEncoding),
    SumEncoding (TaggedObject),
    ToJSON (toEncoding),
    genericParseJSON,
    genericToEncoding,
  )
import Data.Default (Default (def))
import Data.Text (Text)
import GHC.Generics (Generic)
import Pythia.Client.Common (jsonOptions, viaText)
import Pythia.Client.Orphan ()
import Text.PrettyPrint.GenericPretty (Out)

data ChatRequest = ChatRequest
  { model :: Text,
    maxTokens :: Int,
    messages :: [Message],
    stream :: Maybe Bool
  }
  deriving (Generic, Show)

instance Default ChatRequest where
  def =
    ChatRequest
      { model = "claude-haiku-4-5",
        maxTokens = 1000,
        messages = [],
        stream = Nothing
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

data ChatChunk
  = MessageStart {message :: ChatResponse}
  | ContentBlockStart {index :: Int, contentBlock :: Content}
  | ContentBlockDelta {index :: Int, delta :: ContentDeltaUpdate}
  | ContentBlockStop {index :: Int}
  | MessageDelta {messageDelta :: MessageDeltaUpdate, usage :: Maybe Usage}
  | MessageStop
  | Ping
  deriving (Generic, Show)

data ContentDeltaUpdate = ContentDeltaUpdate
  { contentType :: Text,
    text :: Text
  }
  deriving (Generic, Show)

data MessageDeltaUpdate = MessageDeltaUpdate
  { stopReason :: Maybe Text,
    stopSequence :: Maybe Text
  }
  deriving (Generic, Show)

anthropicOptions :: Options
anthropicOptions =
  jsonOptions
    { fieldLabelModifier = \s ->
        if
          | s == "contentType" -> "type"
          | otherwise -> viaText snakify s
    }

chunkOptions :: Options
chunkOptions =
  anthropicOptions
    { constructorTagModifier = viaText snakify,
      fieldLabelModifier = \s ->
        case s of
          "messageDelta" -> "delta"
          _ -> fieldLabelModifier anthropicOptions s,
      sumEncoding = TaggedObject "type" "contents"
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

instance FromJSON ChatChunk where
  parseJSON = genericParseJSON chunkOptions

instance FromJSON ContentDeltaUpdate where
  parseJSON = genericParseJSON anthropicOptions

instance FromJSON MessageDeltaUpdate where
  parseJSON = genericParseJSON anthropicOptions

instance ToJSON ChatResponse where
  toEncoding = genericToEncoding anthropicOptions

instance ToJSON Content where
  toEncoding = genericToEncoding anthropicOptions

instance ToJSON Usage where
  toEncoding = genericToEncoding anthropicOptions

instance ToJSON ChatChunk where
  toEncoding = genericToEncoding chunkOptions

instance ToJSON ContentDeltaUpdate where
  toEncoding = genericToEncoding anthropicOptions

instance ToJSON MessageDeltaUpdate where
  toEncoding = genericToEncoding anthropicOptions

instance Out Message

instance Out Role

instance Out ChatResponse

instance Out Content

instance Out Usage
