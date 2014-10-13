module Main where

import Data.Bits
import Data.ByteString (ByteString, index, pack)
import Data.Word
import Data.Vector (Vector, (!), fromList)

type Word16x4 = (Word16, Word16, Word16, Word16)

fTable :: Vector Word8
fTable = fromList [0xa3,0xd7,0x09,0x83,0xf8,0x48,0xf6,0xf4,0xb3,0x21,0x15,0x78,0x99,0xb1,0xaf,0xf9,
                   0xe7,0x2d,0x4d,0x8a,0xce,0x4c,0xca,0x2e,0x52,0x95,0xd9,0x1e,0x4e,0x38,0x44,0x28,
                   0x0a,0xdf,0x02,0xa0,0x17,0xf1,0x60,0x68,0x12,0xb7,0x7a,0xc3,0xe9,0xfa,0x3d,0x53,
                   0x96,0x84,0x6b,0xba,0xf2,0x63,0x9a,0x19,0x7c,0xae,0xe5,0xf5,0xf7,0x16,0x6a,0xa2,
                   0x39,0xb6,0x7b,0x0f,0xc1,0x93,0x81,0x1b,0xee,0xb4,0x1a,0xea,0xd0,0x91,0x2f,0xb8,
                   0x55,0xb9,0xda,0x85,0x3f,0x41,0xbf,0xe0,0x5a,0x58,0x80,0x5f,0x66,0x0b,0xd8,0x90,
                   0x35,0xd5,0xc0,0xa7,0x33,0x06,0x65,0x69,0x45,0x00,0x94,0x56,0x6d,0x98,0x9b,0x76,
                   0x97,0xfc,0xb2,0xc2,0xb0,0xfe,0xdb,0x20,0xe1,0xeb,0xd6,0xe4,0xdd,0x47,0x4a,0x1d,
                   0x42,0xed,0x9e,0x6e,0x49,0x3c,0xcd,0x43,0x27,0xd2,0x07,0xd4,0xde,0xc7,0x67,0x18,
                   0x89,0xcb,0x30,0x1f,0x8d,0xc6,0x8f,0xaa,0xc8,0x74,0xdc,0xc9,0x5d,0x5c,0x31,0xa4,
                   0x70,0x88,0x61,0x2c,0x9f,0x0d,0x2b,0x87,0x50,0x82,0x54,0x64,0x26,0x7d,0x03,0x40,
                   0x34,0x4b,0x1c,0x73,0xd1,0xc4,0xfd,0x3b,0xcc,0xfb,0x7f,0xab,0xe6,0x3e,0x5b,0xa5,
                   0xad,0x04,0x23,0x9c,0x14,0x51,0x22,0xf0,0x29,0x79,0x71,0x7e,0xff,0x8c,0x0e,0xe2,
                   0x0c,0xef,0xbc,0x72,0x75,0x6f,0x37,0xa1,0xec,0xd3,0x8e,0x62,0x8b,0x86,0x10,0xe8,
                   0x08,0x77,0x11,0xbe,0x92,0x4f,0x24,0xc5,0x32,0x36,0x9d,0xcf,0xf3,0xa6,0xbb,0xac,
                   0x5e,0x6c,0xa9,0x13,0x57,0x25,0xb5,0xe3,0xbd,0xa8,0x3a,0x01,0x05,0x59,0x2a,0x46]

splitWord16 :: Word16 -> [Word8]
splitWord16 x = map fromIntegral [ x .&. 0xFF, (x .&. 0xFF00) `shiftR` 8 ]

combineWord8s :: [Word8] -> Word16
combineWord8s xs = (y `shiftL` 8) .|. x
  where (x:y:[]) = map fromIntegral xs

ruleA :: Word16x4 -> Int -> ByteString -> Word16x4
ruleA (w1, w2, w3, w4) counter key = (gw1 `xor` w4 `xor` (fromIntegral counter), gw1, w2, w3)
  where gw1 = g w1 counter key

ruleB :: Word16x4 -> Int -> ByteString -> Word16x4
ruleB (w1, w2, w3, w4) counter key = (w4, g w1 counter key, w1 `xor` w2 `xor` (fromIntegral counter), w3)

ruleAminus1 :: Word16x4 -> Int -> ByteString -> Word16x4
ruleAminus1 (w1, w2, w3, w4) counter key = (gR w2 counter key, w3, w4, w1 `xor` w2 `xor` (fromIntegral counter))

ruleBMinus1 :: Word16x4 -> Int -> ByteString -> Word16x4
ruleBMinus1 (w1, w2, w3, w4) counter key = (gRw2, gRw2 `xor` w3 `xor` (fromIntegral counter), w4, w1)
  where gRw2 = gR w2 counter key

g :: Word16 -> Int -> ByteString -> Word16
g w k key = combineWord8s $ foldl (foldFunc k) (splitWord16 w) [0..3]
  where foldFunc :: Int -> [Word8] -> Int -> [Word8]
        foldFunc k (g1:g2:[]) i = [g2, (fTable ! (fromIntegral $ g2 `xor` (index key $ (4 * k + i) `mod` 10))) `xor` g1]

gR :: Word16 -> Int -> ByteString -> Word16
gR w k key = combineWord8s [g1, g2]
  where (g5:g6:[]) = splitWord16 w
        g4 = (fTable ! (fromIntegral $ g5 `xor` (index key $ (4 * k + 3) `mod` 10))) `xor` g6
        g3 = (fTable ! (fromIntegral $ g4 `xor` (index key $ (4 * k + 2) `mod` 10))) `xor` g5
        g2 = (fTable ! (fromIntegral $ g3 `xor` (index key $ (4 * k + 1) `mod` 10))) `xor` g4
        g1 = (fTable ! (fromIntegral $ g2 `xor` (index key $ (4 * k) `mod` 10))) `xor` g3

shouldRuleA :: Int -> Bool
shouldRuleA k = k <= 8 || 17 <= k && k <= 24

encrypt :: Word16x4 -> ByteString -> Word16x4
encrypt w key = foldl foldFunc w [1,2..32]
  where foldFunc w k
          | shouldRuleA k = ruleA w k key
          | otherwise = ruleB w k key

decrypt :: Word16x4 -> ByteString -> Word16x4
decrypt w key = foldl foldFunc w [32,31..1]
  where foldFunc w k
          | shouldRuleA k = ruleAminus1 w k key
          | otherwise = ruleBMinus1 w k key

main :: IO ()
main = do
  print $ 1 == combineWord8s (splitWord16 1)
  print $ (1, 2, 3, 4) == decrypt enc key
    where key = pack [1..10]
          enc = encrypt (1, 2, 3, 4) key
