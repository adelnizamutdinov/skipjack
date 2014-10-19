module SkipJack where

import Data.Bits
import Data.Char
import Data.ByteString (ByteString, index)
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

combineTwoWord8 :: [Word8] -> Word16
combineTwoWord8 xs = (y `shiftL` 8) .|. x
  where [x,y] = map fromIntegral xs

ruleA :: ByteString -> Word16x4 -> Int -> Word16x4
ruleA key (w1,w2,w3,w4) counter = (gw1 `xor` w4 `xor` fromIntegral counter, gw1, w2, w3)
  where gw1 = g w1 counter key

ruleB :: ByteString -> Word16x4 -> Int -> Word16x4
ruleB key (w1,w2,w3,w4) counter = (w4, g w1 counter key, w1 `xor` w2 `xor` fromIntegral counter, w3)

ruleAminus1 :: ByteString -> Word16x4 -> Int -> Word16x4
ruleAminus1 key (w1,w2,w3,w4) counter = (gMinus1 w2 counter key, w3, w4, w1 `xor` w2 `xor` fromIntegral counter)

ruleBMinus1 :: ByteString -> Word16x4 -> Int -> Word16x4
ruleBMinus1 key (w1,w2,w3,w4) counter = (gRw2, gRw2 `xor` w3 `xor` fromIntegral counter, w4, w1)
  where gRw2 = gMinus1 w2 counter key

cv :: ByteString -> Int -> Int -> Word8
cv key k i = index key $ (4 * k + i) `mod` 10

g :: Word16 -> Int -> ByteString -> Word16
g w k key = combineTwoWord8 $ foldl foldFunc (splitWord16 w) [0..3]
  where foldFunc [g1,g2] i = [g2, (fTable ! fromIntegral (g2 `xor` cv key k i)) `xor` g1]
        foldFunc  _      _ = error "should have exactly two items in a list"

gMinus1 :: Word16 -> Int -> ByteString -> Word16
gMinus1 w k key = combineTwoWord8 $ foldr foldFunc (splitWord16 w) [0..3]
  where foldFunc i [g5, g6] = [(fTable ! fromIntegral (g5 `xor` cv key k i)) `xor` g6, g5]
        foldFunc _  _       = error "should have exactly two items in a list"

shouldRuleA :: Int -> Bool
shouldRuleA k = k <= 8 || 17 <= k && k <= 24

encryptBlock :: ByteString -> Word16x4 -> Word16x4
encryptBlock key wrds = foldl foldFunc wrds [1..32]
  where foldFunc word k
          | shouldRuleA k = ruleA key word k
          | otherwise = ruleB key word k

decryptBlock :: ByteString -> Word16x4 -> Word16x4
decryptBlock key w = foldr foldFunc w [1..32]
  where foldFunc k word
          | shouldRuleA k = ruleAminus1 key word k
          | otherwise = ruleBMinus1 key word k

encrypt :: ByteString -> String -> String
encrypt _   [] = []
encrypt key s  = blocksToStringRaw $ map (encryptBlock key) (stringToBlocks s) 

decrypt :: ByteString -> String -> String
decrypt _   [] = []
decrypt key s  = blocksToString $ map (decryptBlock key) (stringToBlocksRaw s)

-- hash! 8 22 2

charToByte :: Char -> Word8
charToByte = fromIntegral . ord

byteToChar :: Word8 -> Char
byteToChar = chr . fromIntegral

stringToBytes :: String -> [Word8]
stringToBytes = map charToByte

bytesToString :: [Word8] -> String
bytesToString = map byteToChar

prepare :: String -> String
prepare s
  | m == 0 = s ++ "1" ++ replicate 7 '0'
  | m == 7 = s ++ "1" ++ replicate 8 '0'
  | otherwise = s ++ "1" ++ replicate (7 - m) '0'
  where m = length s `mod` 8

unprepare :: String -> String
unprepare [] = error "prepare your string first"
unprepare s
  | l == '0' = unprepare i
  | l == '1' = i
  | otherwise = error "not properly prepared"
  where l = last s
        i = init s

words8To16 :: [Word8] -> [Word16]
words8To16 (w1:w2:rest) = combineTwoWord8 [w1, w2] : words8To16 rest
words8To16 [] = []
words8To16 _ = error "uneven number of word8s"

words16ToBlocks :: [Word16] -> [Word16x4]
words16ToBlocks (w1:w2:w3:w4:rest) = (w1,w2,w3,w4) : words16ToBlocks rest
words16ToBlocks [] = []
words16ToBlocks _ = error "uneven number of word16s"

blocksToWords16 :: [Word16x4] -> [Word16]
blocksToWords16 = foldl f []
  where f ws (w1,w2,w3,w4) = ws ++ [w1,w2,w3,w4]

words16To8 :: [Word16] -> [Word8]
words16To8 ws = ws >>= splitWord16

stringToBlocks :: String -> [Word16x4]
stringToBlocks = stringToBlocksRaw . prepare

stringToBlocksRaw :: String -> [Word16x4]
stringToBlocksRaw = words16ToBlocks . words8To16 . stringToBytes

blocksToString :: [Word16x4] -> String
blocksToString = unprepare . blocksToStringRaw

blocksToStringRaw :: [Word16x4] -> String
blocksToStringRaw = bytesToString . words16To8 . blocksToWords16
