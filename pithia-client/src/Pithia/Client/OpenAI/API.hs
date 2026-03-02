{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ImportQualifiedPost #-}

module Pithia.Client.OpenAI.API where

import Cases (snakify)
import Data.Aeson
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Generics

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
  toEncoding =
    genericToEncoding
      defaultOptions
        { constructorTagModifier = viaText snakify
        }

viaText :: (Text -> Text) -> String -> String
viaText f = T.unpack . f . T.pack

instance FromJSON Message

instance FromJSON Role where
  parseJSON =
    genericParseJSON
      defaultOptions
        { constructorTagModifier = viaText snakify
        }

instance FromJSON ChatResponse

instance FromJSON Choice
