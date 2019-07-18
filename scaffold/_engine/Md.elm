module Md exposing (parsePage, parsePost, parsePostList)

import Dict exposing (Dict)
import PageType exposing (PageData, PostData, PostList)
import Parser
    exposing
        ( (|.)
        , (|=)
        , DeadEnd
        , Parser
        , Problem(..)
        , Step(..)
        , Trailing(..)
        , chompIf
        , chompUntil
        , getChompedString
        , spaces
        )


type alias File =
    { path : String
    , content : String
    }


parsePost : File -> Result String PostData
parsePost file =
    case parsePreamble file.content of
        Err deadEnds ->
            Err (deadEndsToString deadEnds)

        Ok ( preambleData, markdown ) ->
            Result.map5
                PostData
                (case parseFileDate file.path of
                    Ok date ->
                        Ok date

                    Err err ->
                        Dict.get "date" preambleData
                            |> Result.fromMaybe "No date found!"
                )
                (Ok markdown)
                (Dict.get "tags" preambleData
                    |> Maybe.map (String.split " ")
                    |> Maybe.withDefault []
                    |> Ok
                )
                (Dict.get "title" preambleData
                    |> Result.fromMaybe "No title in preamble!"
                )
                (Ok
                    (file.path
                        |> String.replace "_posts/" ""
                        |> String.dropRight 3
                    )
                )


parsePostList : File -> Result String PostList
parsePostList file =
    case parsePreamble file.content of
        Err deadEnds ->
            Err (deadEndsToString deadEnds)

        Ok ( preambleData, markdown ) ->
            Result.map2 PostList
                (Ok [])
                (Dict.get "title" preambleData
                    |> Result.fromMaybe "No title in preamble!"
                )


parsePage : File -> Result String PageData
parsePage file =
    case parsePreamble file.content of
        Err deadEnds ->
            Err (deadEndsToString deadEnds)

        Ok ( preambleData, markdown ) ->
            Result.map3 PageData
                (Ok markdown)
                (Dict.get "title" preambleData
                    |> Result.fromMaybe "No title in preamble!"
                )
                (Ok
                    (file.path
                        |> String.replace "_pages/" ""
                        |> String.dropRight 3
                    )
                )



-- FILENAME DATE PARSING


parseFileDate : String -> Result String String
parseFileDate path =
    case Parser.run pathDateParser path of
        Err err ->
            Err (deadEndsToString err)

        Ok date ->
            Ok date


pathParser : Parser String
pathParser =
    chompUntil "/"
        |. Parser.symbol "/"
        |> getChompedString


pathDateParser : Parser String
pathDateParser =
    Parser.loop () pathDateHelper


pathDateHelper : () -> Parser (Step () String)
pathDateHelper _ =
    Parser.oneOf
        [ pathParser
            |> Parser.map (\_ -> Loop ())
        , Parser.succeed Done
            |= dateParser
        ]


dateParser : Parser String
dateParser =
    getChompedString <|
        Parser.succeed ()
            |. chompIf Char.isDigit
            |. chompIf Char.isDigit
            |. chompIf Char.isDigit
            |. chompIf Char.isDigit
            |. chompIf ((==) '-')
            |. chompIf Char.isDigit
            |. chompIf Char.isDigit
            |. chompIf ((==) '-')
            |. chompIf Char.isDigit
            |. chompIf Char.isDigit



-- PREAMBLE PARSING


contentsParser : Parser ( Dict String String, String )
contentsParser =
    Parser.succeed
        (\preamble offset source ->
            ( preamble, String.dropLeft offset source )
        )
        |= preambleParser
        |= Parser.getOffset
        |= Parser.getSource


preambleParser : Parser (Dict String String)
preambleParser =
    Parser.succeed identity
        |. Parser.keyword "---"
        |. Parser.symbol "\n"
        |= Parser.loop Dict.empty pairHelper


pairHelper : Dict String String -> Parser (Step (Dict String String) (Dict String String))
pairHelper pairs =
    Parser.oneOf
        [ Parser.keyword "---\n"
            |> Parser.map (\_ -> Done pairs)
        , Parser.succeed
            (\( key, val ) -> Loop (Dict.insert key val pairs))
            |= pairParser
        ]


pairParser : Parser ( String, String )
pairParser =
    Parser.succeed (\k v -> ( String.trim k, String.trim v ))
        |= (chompUntil ":" |> getChompedString)
        |. Parser.symbol ":"
        |= (chompUntil "\n" |> getChompedString)
        |. Parser.symbol "\n"


parsePreamble : String -> Result (List DeadEnd) ( Dict String String, String )
parsePreamble text =
    Parser.run contentsParser text


deadEndsToString : List DeadEnd -> String
deadEndsToString deadEnds =
    List.map deadEndToString deadEnds
        |> String.join "\n\n"


deadEndToString : DeadEnd -> String
deadEndToString deadEnd =
    "I ran into a problem on row: "
        ++ String.fromInt deadEnd.row
        ++ " at col: "
        ++ String.fromInt deadEnd.col
        ++ ":\n"
        ++ problemToString deadEnd.problem


problemToString : Problem -> String
problemToString problem =
    case problem of
        Expecting str ->
            "I was expecting " ++ str

        ExpectingInt ->
            "I was expecting an int"

        ExpectingHex ->
            "I was expecting a hex value"

        ExpectingOctal ->
            "I was expecting an octal value"

        ExpectingBinary ->
            "I was expecting binary"

        ExpectingFloat ->
            "I was expecting a float"

        ExpectingVariable ->
            "I was expecting a variable"

        ExpectingSymbol str ->
            "I was expecting a symbol " ++ str

        ExpectingKeyword str ->
            "I was expecting a keyword " ++ str

        ExpectingEnd ->
            "I was expecting the end of the input"

        UnexpectedChar ->
            "I did not expect that character"

        Problem str ->
            str

        BadRepeat ->
            "The repeat was bad?"

        ExpectingNumber ->
            "I was expecting a number"
