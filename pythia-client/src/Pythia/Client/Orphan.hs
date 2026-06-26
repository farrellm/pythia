{-# OPTIONS_GHC -Wno-orphans #-}

module Pythia.Client.Orphan () where

import Data.Text (Text)
import qualified Data.Text as T
import Text.PrettyPrint.GenericPretty (Out (..))

instance Out Text where
  docPrec a = docPrec a . T.unpack
  doc = doc . T.unpack
