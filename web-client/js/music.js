/**
 * Created by Mantas on 12/03/2017.
 */

var audio = new Audio();
var ID;
var submitted = false;

window.onload=function(){

    // find template and compile it
    var templateSource = document.getElementById('results-template').innerHTML,
        template = Handlebars.compile(templateSource),
        resultsPlaceholder = document.getElementById('results'),
        audioObject = null;

    var searchAlbums = function (query) {
        $.ajax({
            url: 'https://api.spotify.com/v1/search',
            data: {
                q: query,
                type: 'track'
            },
            success: function (response) {
                resultsPlaceholder.innerHTML = template(response);
                $(function(){
                    console.log('ready');
                    $('.list-group div').click(function(e) {
                        e.preventDefault()

                        $that = $(this);

                        $that.parent().find('div').removeClass('active');
                        $that.addClass('active');
                        ID = $that[0].dataset.albumId;
                    });
                });

            }
        });
    };

    function playSong(query) {
        $.ajax({
            url: 'https://api.spotify.com/v1/tracks/' + query,
            data: {
                id: query
            },
            success: function (response) {
                var track = response.preview_url;
                audio.src = track;
                audio.play();
            }
        });
    }

    document.getElementById('results').addEventListener('click', function (e) {
        ID = JSON.stringify(e.target.dataset.albumId);
        ID = ID.replace(/"/g, "");
        playSong(ID);
    });

    document.getElementById('search-form').addEventListener('submit', function (e) {
        e.preventDefault();
        searchAlbums(document.getElementById('song').value);
    }, false);
};

function pauseSong() {
    audio.pause();
}
function resumeSong() {
    audio.play();
}

function submitSong() {
    if (place == null || ID == null) return;
     console.log(place);
     submitted = true;
     polies.push(candidate);
     candidate = null;
     console.log(ID);
}
