{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}

module Numeric.Units.Dimensional.Presentation
(
  -- * Presentation Quantities
  PresentationQuantity(..)
  -- * Presentation Formats
, PresentationFormat(..)
, defaultFormat
, defaultFormatIn
, simpleFormat
  -- ** For Floating-Point Values
, scientificFormat, scientificFormatIn
, decimalFormat, decimalFormatIn
)
where

import Data.Data
import GHC.Generics
import Numeric (showFFloat, showEFloat)
import Numeric.Units.Dimensional
import Numeric.Units.Dimensional.SIUnits

data PresentationQuantity d a = Simple a (Unit 'NonMetric d a)
                              | Composite Integer (Unit 'NonMetric d a) (PresentationQuantity d a)
  deriving (Eq, Generic, Generic1, Typeable)

data PresentationFormat d a = SimpleFormat (a -> String -> String) (PresentationUnit d a)
                            | CompositeFormat (Unit 'NonMetric d a) (PresentationFormat d a)

data PresentationUnit d a = SimpleUnit (Unit 'NonMetric d a)
                          | PrefixedUnit (Unit 'Metric d a)
                          | PrefixedUnitMajor (Unit 'Metric d a)

simpleUnit :: Unit m d a -> PresentationUnit d a
simpleUnit = SimpleUnit . weaken

chooseUnit :: (RealFrac a, Floating a) => PresentationUnit d a -> Quantity d a -> Unit 'NonMetric d a
chooseUnit (SimpleUnit u)        _ = u
chooseUnit (PrefixedUnit u)      q = withAppropriatePrefix u q
chooseUnit (PrefixedUnitMajor u) q = withAppropriatePrefix' u q

-- | Constructs a 'PresentationFormat' from a showing function and a 'Unit'.
simpleFormat :: (a -> ShowS) -> Unit m d a -> PresentationFormat d a
simpleFormat s u = SimpleFormat s (simpleUnit u)

-- | Creates a 'PresentationFormat' for a 'Show'able representation from a specified 'Unit'.
defaultFormatIn :: (Num a, Show a) => Unit m d a -> PresentationFormat d a
defaultFormatIn = simpleFormat shows

-- | A 'PresentationFormat' which 'show's the value in the 'siUnit' of its dimension.
defaultFormat :: (Num a, Show a, KnownDimension d) => PresentationFormat d a
defaultFormat = defaultFormatIn siUnit

-- | A 'PresentationFormat' which displays a value in scientific notation, in a specified unit,
-- and with an optionally-specified number of digits after the decimal point.
scientificFormatIn :: (RealFloat a) => Maybe Int -> Unit m d a -> PresentationFormat d a
scientificFormatIn d = simpleFormat (showEFloat d)

-- | A 'PresentationFormat' which displays a value in scientific notation, in the 'siUnit' of its dimension,
-- and with an optionally-specified number of digits after the decimal point.
scientificFormat :: (RealFloat a, KnownDimension d) => Maybe Int -> PresentationFormat d a
scientificFormat d = scientificFormatIn d siUnit

-- | A 'PresentationFormat' which displays a value in decimal notation, in a specified unit,
-- and with an optionally-specified number of digits after the decimal point.
decimalFormatIn :: (RealFloat a) => Maybe Int -> Unit m d a -> PresentationFormat d a
decimalFormatIn d = simpleFormat (showFFloat d)

-- | A 'PresentationFormat' which displays a value in decimal notation, in the 'siUnit' of its dimension,
-- and with an optionally-specified number of digits after the decimal point.
decimalFormat :: (RealFloat a, KnownDimension d) => Maybe Int -> PresentationFormat d a
decimalFormat d = decimalFormatIn d siUnit
