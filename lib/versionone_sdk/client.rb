require 'faraday'
require 'versionone_sdk/update'
require 'versionone_sdk/parser_xml_assets'

module VersiononeSdk
  class Client

    attr_accessor :oFaraday
    attr_accessor :sInstance

    def initialize(dOptions={})
      iPort        = iPort.to_i if iPort.is_a?(String)
      @sProtocol   = dOptions.has_key?(:protocol) && dOptions[:protocol] \
                   ? dOptions[:protocol]    : 'https'
      @sHostname   = dOptions.has_key?(:hostname) && dOptions[:hostname] \
                   ? dOptions[:hostname]    : 'localhost'
      @iPort       = dOptions.has_key?(:port) && dOptions[:port] \
                   ? dOptions[:port].to_i   : 443
      sUsername    = dOptions.has_key?(:username) ? dOptions[:username] : ''
      sPassword    = dOptions.has_key?(:password) ? dOptions[:password] : ''
      @sInstance   = dOptions.has_key?(:instance) ? dOptions[:instance] : ''
      @dTypePrefix = { 'B' => 'Story', 'E' => 'Epic' }
      @sUrl        = buildUrl(@sProtocol,@sHostname,@iPort)
      @oFaraday    = Faraday::Connection.new url: @sUrl
      @oFaraday.basic_auth(sUsername, sPassword)
      @oUpdate     = VersiononeSdk::Update.new(self)
    end

    def getAsset(xAssetId1=nil,xAssetId2=nil)
      if !xAssetId1.nil?
        xAssetId1.strip!

        if xAssetId1 =~ /^([^:]+):([0-9]+)$/
          sAssetType = $1
          sAssetOid  = $2.to_i
          return self.getAssetForTypeAndOid( sAssetType, sAssetOid )

        elsif xAssetId1 =~ /^([a-zA-Z])-[0-9]+$/
          sAssetTypeAbbr = $1.upcase
          sAssetType     = @dTypePrefix.has_key?( sAssetTypeAbbr ) \
            ? @dTypePrefix[ sAssetTypeAbbr ] : ''
          xAssetId1.upcase!
          return self.getAssetForTypeAndNumber( sAssetType, xAssetId1 )

        elsif !xAssetId2.nil?
          if xAssetId2.is_a?(String) && xAssetId2 =~ /^[0-9]+$/
            xAssetId2 = xAssetId2.to_i
          end

          if xAssetId2.is_a?(Integer)

            if xAssetId1     =~ /^[a-zA-Z]$/
              xAssetId1.upcase!
              sAssetTypeAbbr = xAssetId1
              sAssetType     = @dTypePrefix.has_key?( sAssetTypeAbbr ) \
                ? @dTypePrefix[ sAssetTypeAbbr ] : ''
              sAssetNumber   =  xAssetId1 + '-' + xAssetId2.to_s
              sAssetNumber.upcase!
              return self.getAssetForTypeAndNumber( sAssetType, sAssetNumber )
            elsif xAssetId1 =~ /^[a-zA-Z].+$/
              return self.getAssetForTypeAndOid( xAssetId1, xAssetId2 )
            end

          end

        end
      else
        raise RuntimeError, 'E_NO_ASSET_ID'
      end
      raise RuntimeError, "E_UNKNOWN_ASSET_ID [#{xAssetId1}][#{xAssetId2.to_s}]"
    end

    def getAssetForTypeAndOid(sAssetType=nil,sAssetOid=nil)
      sUrl    = self.getUrlForAssets( sAssetType, sAssetOid )
      puts(sUrl)
      oRes    = @oFaraday.get sUrl
      oParser = VersiononeSdk::ParserXmlAssets.new({:url => @sUrl})
      aDoc    = oParser.getDocForAssetXml( oRes.body )
    end

    def getAssetForTypeAndNumber(sAssetType=nil,sAssetNumber=nil)
      sUrl    = self.getUrlForAssetTypeAndNumber( sAssetType, sAssetNumber )
      oRes    = @oFaraday.get sUrl
      oParser = VersiononeSdk::ParserXmlAssets.new({:url => @sUrl})
      aDocs   = oParser.getDocsForAssetsXml( oRes.body )
      return aDocs[0]
    end

    def getAssets(sAssetType=nil,xIds=nil)
      oRes    = self.getAssetsXml(sAssetType,xIds)
      oParser = VersiononeSdk::ParserXmlAssets.new({:url => @sUrl})
      aDocs   = oParser.getDocsForAssetsXml( oRes.body )
      return aDocs
    end

    def getAssetsXml(sAssetType=nil,xIds=nil)
      sUrl = self.getUrlForAssets(sAssetType)
      oRes = @oFaraday.get sUrl
      return oRes
    end

    def getUrlForAssetTypeAndNumber(sAssetType=nil,sAssetNumber=nil)
      aUrl = [ @sUrl, @sInstance, 'rest-1.v1/Data',sAssetType + %Q!?where=Number="#{sAssetNumber}"!]
      sUrl = aUrl.join('/')
      return sUrl
    end

    def getUrlForAssets(sAssetType=nil,sAssetOid=nil)
      aUrl = [ @sUrl, @sInstance, 'rest-1.v1/Data',sAssetType]
      if sAssetOid.is_a?(Integer)
        aUrl.push( sAssetOid )
      elsif sAssetOid.kind_of?(String) && sAssetOid =~ /^[0-9]+$/
        aUrl.push( sAssetOid )
      end
      sUrl = aUrl.join('/')
      return sUrl
    end

    def updateAsset(sAssetType=nil,sAssetOid=nil,sName=nil,xxValues=nil,yTagType=nil)
      return @oUpdate.updateAsset(sAssetType,sAssetOid,sName,xxValues,yTagType)
    end

    private

    def buildUrl(sProtocol='http',sHostname='localhost',iPort=80)
      if sHostname.nil?
        sHostname = 'localhost'
      elsif sHostname.is_a?(String)
        sHostname.strip!
        if sHostname.length < 1
          sHostname = 'localhost'
        end
      else
        raise ArgumentError, 'E_HOSTNAME_IS_NOT_A_STRING'
      end
      if iPort.nil?
        iPort = 80
      elsif iPort.is_a?(String) && iPort =~ /^[0-9]+$/
        iPort = iPort.to_i
      elsif ! iPort.kind_of?(Integer)
        raise ArgumentError, 'E_PORT_IS_NOT_AN_INTEGER'
      end
      sBaseUrl   = "#{sProtocol}://#{sHostname}"
      sBaseUrl.sub!(/\/+\s*$/,'')
      sBaseUrl  += ':' + iPort.to_s if iPort != 80
      return sBaseUrl
    end

  end
end