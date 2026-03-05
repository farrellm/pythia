{-# LANGUAGE ImportQualifiedPost #-}

module Pithia.Client.Common
  ( viaText,
    jsonOptions,
    pshow,
    pprint,
  )
where

import Cases (snakify)
import Control.Monad.IO.Class (MonadIO (liftIO))
import Data.Aeson
  ( Options (constructorTagModifier, fieldLabelModifier),
    defaultOptions,
  )
import Data.Aeson.Encode.Pretty (encodePretty)
import Data.Aeson.Types (ToJSON)
import Data.ByteString.Lazy qualified as LB
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Data.Text.IO qualified as TIO

viaText :: (Text -> Text) -> String -> String
viaText f = T.unpack . f . T.pack

jsonOptions :: Options
jsonOptions =
  defaultOptions
    { constructorTagModifier = viaText snakify,
      fieldLabelModifier = viaText snakify
    }

pshow :: (ToJSON a) => a -> Text
pshow = decodeUtf8 . LB.toStrict . encodePretty

pprint :: (MonadIO m, ToJSON a) => a -> m ()
pprint a = liftIO . TIO.putStrLn $ pshow a
