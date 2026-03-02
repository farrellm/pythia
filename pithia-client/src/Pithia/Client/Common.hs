{-# LANGUAGE ImportQualifiedPost #-}

module Pithia.Client.Common where

import Cases (snakify)
import Data.Aeson
  ( Options (constructorTagModifier),
    defaultOptions,
  )
import Data.Text (Text)
import Data.Text qualified as T

viaText :: (Text -> Text) -> String -> String
viaText f = T.unpack . f . T.pack

jsonOptions :: Options
jsonOptions =
  defaultOptions
    { constructorTagModifier = viaText snakify
    }
