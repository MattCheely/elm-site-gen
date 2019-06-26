module PageType exposing
    ( PageData
    , PageType(..)
    , PostData
    , PostList
    , encode
    , postDataDecoder
    , postListDecoder
    , postPath
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type PageType
    = Post PostData
    | Posts PostList
    | Page PageData


type alias PostList =
    { posts : List PostData
    , title : String
    }


type alias PostData =
    { date : String
    , content : String
    , tags : List String
    , title : String
    , slug : String
    }


type alias PageData =
    { content : String
    , title : String
    , slug : String
    }


encode : PageType -> Value
encode pageType =
    case pageType of
        Post postData ->
            Encode.object
                [ ( "layout", Encode.string "Post" )
                , ( "data", encodePostData postData )
                ]

        Posts postList ->
            Encode.object
                [ ( "layout", Encode.string "Posts" )
                , ( "data", encodePostList postList )
                ]

        Page pageData ->
            Debug.todo "Handle Pages"


postPath : PostData -> String
postPath postData =
    "posts/" ++ postData.slug ++ "/"


encodePostData : PostData -> Value
encodePostData postData =
    Encode.object
        [ ( "date", Encode.string postData.date )
        , ( "content", Encode.string postData.content )
        , ( "tags", Encode.list Encode.string postData.tags )
        , ( "title", Encode.string postData.title )
        , ( "slug", Encode.string postData.slug )
        , ( "outputPath", Encode.string (postPath postData ++ "index.html") )
        ]


postDataDecoder : Decoder PostData
postDataDecoder =
    Decode.map5 PostData
        (Decode.field "date" Decode.string)
        (Decode.field "content" Decode.string)
        (Decode.field "tags" <| Decode.list Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "slug" Decode.string)


encodePostList : PostList -> Value
encodePostList postList =
    Encode.object
        [ ( "title", Encode.string postList.title )
        , ( "posts", Encode.list encodePostData postList.posts )
        , ( "outputPath", Encode.string "posts/index.html" )
        ]


postListDecoder : Decoder PostList
postListDecoder =
    Decode.map2 PostList
        (Decode.field "posts" (Decode.list postDataDecoder))
        (Decode.field "title" Decode.string)
