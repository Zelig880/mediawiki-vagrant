# == Class: role::wikimediaproduction
# This meta-role pulls in a lot of other roles that are available in Wikimedia production.
class role::wikimediaproduction {
    include ::role::abusefilter
    include ::role::antispam
    include ::role::antispoof
    include ::role::babel
    include ::role::betafeatures
    include ::role::campaigns
    include ::role::categorytree
    include ::role::centralauth
    include ::role::centralnotice
    include ::role::checkuser
    include ::role::cirrussearch
    include ::role::cite
    include ::role::citoid
    include ::role::cldr
    include ::role::codeeditor
    include ::role::codemirror
    include ::role::cologneblue
    include ::role::confirmedit
    include ::role::contactpage
    include ::role::contenttranslation
    include ::role::disableaccount
    include ::role::disambiguator
    include ::role::easytimeline
    include ::role::echo
    include ::role::education
    include ::role::eventbus
    include ::role::eventlogging
    include ::role::featuredfeeds
    include ::role::fileannotations
    include ::role::flaggedrevs
    include ::role::flow
    include ::role::gadgets
    include ::role::geodata
    include ::role::geshi
    include ::role::gettingstarted
    include ::role::globalblocking
    include ::role::globalcssjs
    include ::role::globalusage
    include ::role::globaluserpage
    include ::role::graph
    include ::role::graphoid
    include ::role::guidedtour
    include ::role::https
    include ::role::inputbox
    include ::role::interwiki
    include ::role::kartographer
    include ::role::l10nupdate
    include ::role::labeledsectiontransclusion
    include ::role::maps
    include ::role::massmessage
    include ::role::math
    include ::role::mathoid
    include ::role::mobileapp
    include ::role::mobilecontentservice
    include ::role::mobilefrontend
    include ::role::modern
    include ::role::monobook
    include ::role::multimedia
    include ::role::multimediaviewer
    include ::role::navigationtiming
    include ::role::newusermessage
    include ::role::nuke
    include ::role::oathauth
    include ::role::oauth
    include ::role::oauthauthentication
    include ::role::ores
    include ::role::pageassessments
    include ::role::pagedtiffhandler
    include ::role::pageimages
    include ::role::pagetriage
    include ::role::pageviewinfo
    include ::role::parserfunctions
    include ::role::parsoid
    include ::role::pdfhandler
    include ::role::poem
    include ::role::poolcounter
    include ::role::popups
    include ::role::proofreadpage
    include ::role::quicksurveys
    include ::role::relatedarticles
    include ::role::renameuser
    include ::role::restbase
    include ::role::revisionslider
    include ::role::sandboxlink
    include ::role::score
    include ::role::scribunto
    include ::role::securepoll
    include ::role::sitematrix
    include ::role::templatedata
    include ::role::templatesandbox
    include ::role::textextracts
    include ::role::throttleoverride
    include ::role::timedmediahandler
    include ::role::titleblacklist
    include ::role::torblock
    include ::role::translate
    include ::role::uls
    include ::role::uploadwizard
    include ::role::vipsscaler
    include ::role::visualeditor
    include ::role::wikieditor
    include ::role::wikihiero
    include ::role::wikilove
    include ::role::wikimediaevents
    include ::role::wikimediaflow
    include ::role::wikimediaincubator
    include ::role::wikimediamaintenance
    include ::role::wikimediamessages
    include ::role::zero
}
