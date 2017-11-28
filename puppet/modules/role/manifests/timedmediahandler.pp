# == Class: role::timedmediahandler
# This role provisions the TimedMediaHandler[https://www.mediawiki.org/wiki/Extension:TimedMediaHandler] extension,
# which displays audio and video files and their captions.
class role::timedmediahandler {
    include ::role::multimedia

    require_package('ffmpeg2theora')
    require_package('ffmpeg')

    mediawiki::extension { 'MwEmbedSupport': }

    mediawiki::extension { 'TimedMediaHandler':
        settings     => {
            wgWaitTimeForTranscodeReset => 1,
            wgFFmpegLocation            => '/usr/bin/ffmpeg'
        },
        needs_update => true,
        require      => [
            Package['ffmpeg', 'ffmpeg2theora'],
            Mediawiki::Extension['MwEmbedSupport']
        ],
    }
}
