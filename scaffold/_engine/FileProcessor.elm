port module FileProcessor exposing (main)

import Content exposing (Content(..), PageData, PostData)
import Json.Encode as Encode
import Md
import Platform exposing (worker)
import SiteConfig exposing (SiteConfig)


type alias SiteSrc =
    { config : SiteConfig
    , files : List File
    }


type alias File =
    { path : String
    , content : String
    }


parseFileData : List File -> Result String (List Content)
parseFileData files =
    List.map parseFile files
        -- TODO: It would be nicer if this collected all errors
        |> List.foldr (Result.map2 (::)) (Ok [])


parseFile : File -> Result String Content
parseFile file =
    let
        fileType =
            getFileType file.path

        category =
            getCategory file.path

        errWithPath err =
            file.path ++ ": " ++ err
    in
    case ( category, fileType ) of
        ( PostCategory, Markdown ) ->
            Md.parsePost file
                |> Result.map Post
                |> Result.mapError errWithPath

        ( PageCategory, Markdown ) ->
            Md.parsePage file
                |> Result.map Page
                |> Result.mapError errWithPath

        ( PostListCategory, Markdown ) ->
            Md.parsePostList file
                |> Result.map Posts
                |> Result.mapError errWithPath

        ( _, Unknown ) ->
            Ok (Static file.path file.path)

        ( UnknownCategory, _ ) ->
            Err "unknown file category."


type FileType
    = Markdown
    | Unknown


getFileType path =
    if String.endsWith ".md" path then
        Markdown

    else
        Unknown


getCategory path =
    if String.startsWith "pages/" path then
        PageCategory

    else if path == "posts/index.md" then
        PostListCategory

    else if String.startsWith "posts/" path then
        PostCategory

    else
        UnknownCategory


type Category
    = PageCategory
    | PostCategory
    | PostListCategory
    | UnknownCategory


init : SiteSrc -> ( (), Cmd msg )
init siteSrc =
    let
        json =
            case parseFileData siteSrc.files of
                Ok fileData ->
                    Encode.object
                        [ ( "siteConfig", SiteConfig.encode siteSrc.config )
                        , ( "files"
                          , fileData
                                |> addListings
                                |> Encode.list Content.encode
                          )
                        ]

                Err problem ->
                    Encode.object [ ( "error", Encode.string problem ) ]
    in
    ( (), sendFileData json )


addListings : List Content -> List Content
addListings pages =
    let
        posts =
            List.filterMap
                (\page ->
                    case page of
                        Post postData ->
                            Just postData

                        _ ->
                            Nothing
                )
                pages
    in
    pages
        |> List.map
            (\page ->
                case page of
                    Posts postList ->
                        Posts { postList | posts = posts }

                    _ ->
                        page
            )


port sendFileData : Encode.Value -> Cmd msg



-- MAIN


main : Program SiteSrc () msg
main =
    worker
        { init = init
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = always Sub.none
        }
