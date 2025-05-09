<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:ccda="urn:hl7-org:v3"
                xmlns:fhir="http://hl7.org/fhir">

  <xsl:output method="text"/>
  
  <!-- Root template -->
  <xsl:param name="currentTimestamp"/>
  <xsl:variable name="patientRoleId" select="//ccda:patientRole/ccda:id/@extension"/>
  <xsl:variable name="patientResourceName" select="concat(//ccda:patientRole/ccda:patient/ccda:name/ccda:family, ' ', //ccda:patientRole/ccda:patient/ccda:name/ccda:given)"/>
  <xsl:variable name="bundleTimestamp" select="//ccda:effectiveTime/@value"/>
  
  <xsl:param name="bundleId"/>
  <xsl:param name="patientResourceId"/>
  <xsl:param name="encounterResourceId"/>
  <xsl:param name="consentResourceId"/>
  <xsl:param name="organizationResourceId"/>
  <xsl:param name="questionnaireResourceId"/>
  <xsl:param name="observationResourceSha256Id"/>
  <xsl:param name="sexualOrientationResourceId"/>
  <xsl:param name="questionnaireResponseResourceSha256Id"/>

  <!-- Parameters to get FHIR resource profile URLs -->
  <xsl:param name="baseFhirUrl"/>
  <xsl:param name="bundleMetaProfileUrl"/>
  <xsl:param name="patientMetaProfileUrl"/>
  <xsl:param name="consentMetaProfileUrl"/>
  <xsl:param name="encounterMetaProfileUrl"/>
  <xsl:param name="organizationMetaProfileUrl"/>
  <xsl:param name="observationMetaProfileUrl"/>
  <xsl:param name="observationSexualOrientationMetaProfileUrl"/>
  <xsl:param name="questionnaireMetaProfileUrl"/>
  <xsl:param name="questionnaireResponseMetaProfileUrl"/>
  <xsl:param name="practitionerMetaProfileUrl"/>

  <xsl:variable name="bundleMetaProfileUrlFull" select="concat($baseFhirUrl, $bundleMetaProfileUrl)"/>
  <xsl:variable name="patientMetaProfileUrlFull" select="concat($baseFhirUrl, $patientMetaProfileUrl)"/>
  <xsl:variable name="consentMetaProfileUrlFull" select="concat($baseFhirUrl, $consentMetaProfileUrl)"/>
  <xsl:variable name="encounterMetaProfileUrlFull" select="concat($baseFhirUrl, $encounterMetaProfileUrl)"/>
  <xsl:variable name="organizationMetaProfileUrlFull" select="concat($baseFhirUrl, $organizationMetaProfileUrl)"/>
  <xsl:variable name="observationMetaProfileUrlFull" select="concat($baseFhirUrl, $observationMetaProfileUrl)"/>
  <xsl:variable name="observationSexualOrientationMetaProfileUrlFull" select="concat($baseFhirUrl, $observationSexualOrientationMetaProfileUrl)"/>
  <xsl:variable name="questionnaireMetaProfileUrlFull" select="concat($baseFhirUrl, $questionnaireMetaProfileUrl)"/>
  <xsl:variable name="questionnaireResponseMetaProfileUrlFull" select="concat($baseFhirUrl, $questionnaireResponseMetaProfileUrl)"/>
  <xsl:variable name="practitionerMetaProfileUrlFull" select="concat($baseFhirUrl, $practitionerMetaProfileUrl)"/>

  <xsl:template match="/">
  {
    "resourceType": "Bundle",
    "id": "<xsl:value-of select='$bundleId'/>",
    "meta": {
      "lastUpdated": "<xsl:value-of select='$currentTimestamp'/>",
      "profile": [
        "<xsl:value-of select='$bundleMetaProfileUrlFull'/>"
      ]
    },
    "type": "transaction"
    <xsl:if test="$bundleTimestamp"> 
      , "timestamp": "<xsl:call-template name="formatDateTime">
                          <xsl:with-param name="dateTime" select="$bundleTimestamp"/>
                      </xsl:call-template>"
    </xsl:if>
    , "entry": [
      <xsl:apply-templates select="/ccda:ClinicalDocument/ccda:patientRole 
                                | /ccda:ClinicalDocument/ccda:encompassingEncounter 
                                | //ccda:sexualOrientation/ccda:entry/ccda:observation
                                | //ccda:observations/ccda:entry
                                | /ccda:ClinicalDocument/ccda:consent 
                                | /ccda:ClinicalDocument/ccda:author
                                | //ccda:Questionnaire
                                | //ccda:component/ccda:structuredBody/ccda:component/ccda:encounters/ccda:entry[position()=1]/ccda:encounter
                                "/>
        <xsl:apply-templates select="ccda:observation" mode="questionnaireresponse"/>
    ]
  }
  </xsl:template>

  <!-- Patient Template -->
  <xsl:template name="Patient" match="/ccda:ClinicalDocument/ccda:patientRole">
    {
      "fullUrl": "<xsl:value-of select='$baseFhirUrl'/>/Patient/<xsl:value-of select='$patientResourceId'/>",
      "resource": {
        "resourceType": "Patient",
        "id": "<xsl:value-of select='$patientResourceId'/>",
        "meta": {
          "lastUpdated": "<xsl:value-of select='$currentTimestamp'/>",
          "profile": ["<xsl:value-of select='$patientMetaProfileUrlFull'/>"]
        }
        <xsl:if test="string(ccda:patient/ccda:languageCommunication/ccda:languageCode/@code)">
        , "language": "<xsl:value-of select="ccda:patient/ccda:languageCommunication/ccda:languageCode/@code"/>"
        </xsl:if>
        <!--If there is Official Name, print it, otherwise print first occuring name-->
        <xsl:if test="ccda:patient/ccda:name[@use='L']">
            , "name": [
                <xsl:call-template name="generateNameJson">
                    <xsl:with-param name="selectedName" select="ccda:patient/ccda:name[@use='L']"/>
                </xsl:call-template>
            ]
        </xsl:if>
        <xsl:if test="not(ccda:patient/ccda:name[@use='L']) and ccda:patient/ccda:name[1]">
            , "name": [
                <xsl:call-template name="generateNameJson">
                    <xsl:with-param name="selectedName" select="ccda:patient/ccda:name[1]"/>
                </xsl:call-template>
            ]
        </xsl:if>
        , "gender": "<xsl:choose>
                        <xsl:when test="ccda:patient/ccda:administrativeGenderCode/@nullFlavor">
                            <xsl:call-template name="getNullFlavorDisplay">
                                <xsl:with-param name="nullFlavor" select="ccda:patient/ccda:administrativeGenderCode/@nullFlavor"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="ccda:patient/ccda:administrativeGenderCode/@displayName">
                            <xsl:value-of select="translate(ccda:patient/ccda:administrativeGenderCode/@displayName, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
                        </xsl:when>
                        <xsl:when test="ccda:patient/ccda:administrativeGenderCode/@code='M'">male</xsl:when>
                        <xsl:when test="ccda:patient/ccda:administrativeGenderCode/@code='F'">female</xsl:when>
                        <xsl:when test="ccda:patient/ccda:administrativeGenderCode/@code='UN'">other</xsl:when>
                        <xsl:otherwise><xsl:value-of select="ccda:patient/ccda:administrativeGenderCode/@code"/></xsl:otherwise>
                    </xsl:choose>"
        <xsl:if test="string(ccda:patient/ccda:birthTime/@value)">
        , "birthDate": "<xsl:choose>
                        <xsl:when test='string-length(ccda:patient/ccda:birthTime/@value) >= 8'>
                          <xsl:value-of select='concat(substring(ccda:patient/ccda:birthTime/@value, 1, 4), "-", substring(ccda:patient/ccda:birthTime/@value, 5, 2), "-", substring(ccda:patient/ccda:birthTime/@value, 7, 2))'/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select='ccda:patient/ccda:birthTime/@value'/>
                        </xsl:otherwise>
                      </xsl:choose>"
        </xsl:if>
        <xsl:if test="ccda:addr[not(@nullFlavor)]">
            , "address": [
                <xsl:for-each select="ccda:addr[not(@nullFlavor)]">
                    {
                        <xsl:if test="@use">
                            "use": "<xsl:choose>
                                <xsl:when test="@use='HP' or @use='H'">home</xsl:when>
                                <xsl:when test="@use='WP'">work</xsl:when>
                                <xsl:when test="@use='TMP'">temp</xsl:when>
                                <xsl:when test="@use='OLD' or @use='BAD'">old</xsl:when>
                                <xsl:otherwise><xsl:value-of select="@use"/></xsl:otherwise>
                            </xsl:choose>",
                        </xsl:if>
                        <xsl:if test="string(ccda:streetAddressLine) or string(ccda:city) or string(ccda:state) or string(ccda:postalCode)">
                            "text": "<xsl:for-each select="ccda:streetAddressLine">
                                  <xsl:value-of select="."/>
                                  <xsl:if test="position() != last()">, </xsl:if>
                              </xsl:for-each>
                              <xsl:if test="string(ccda:city)"> <xsl:text> </xsl:text><xsl:value-of select="ccda:city"/></xsl:if>
                              <xsl:if test="string(ccda:state)">, <xsl:value-of select="ccda:state"/></xsl:if>
                              <xsl:if test="string(ccda:postalCode)"> <xsl:text> </xsl:text><xsl:value-of select="ccda:postalCode"/></xsl:if>" ,
                        </xsl:if>
                        <xsl:if test="ccda:streetAddressLine">
                            "line": [
                                <xsl:for-each select="ccda:streetAddressLine">
                                    "<xsl:value-of select="."/>"
                                    <xsl:if test="position() != last()">, </xsl:if>
                                </xsl:for-each>
                            ]
                        </xsl:if>
                        <xsl:if test="string(ccda:city)">
                            , "city": "<xsl:value-of select="ccda:city"/>"
                        </xsl:if>
                        <xsl:if test="string(ccda:county)">
                            , "district": "<xsl:value-of select="ccda:county"/>"
                        </xsl:if>
                        <xsl:if test="string(ccda:state)">
                            , "state": "<xsl:value-of select="ccda:state"/>"
                        </xsl:if>
                        <xsl:if test="string(ccda:postalCode)">
                            , "postalCode": "<xsl:value-of select="ccda:postalCode"/>"
                        </xsl:if>
                        <xsl:if test="string(ccda:country)">
                            , "country": "<xsl:value-of select="ccda:country"/>"
                        </xsl:if>
                        <xsl:if test="ccda:useablePeriod">
                            ,"period": {
                                <xsl:if test="string(ccda:useablePeriod/ccda:low/@value)">
                                    "start": "<xsl:call-template name="formatDateTime">
                                                  <xsl:with-param name="dateTime" select="ccda:useablePeriod/ccda:low/@value"/>
                                              </xsl:call-template>"
                                </xsl:if>
                                <xsl:if test="string(ccda:useablePeriod/ccda:high/@value)">
                                    <xsl:if test="string(ccda:useablePeriod/ccda:low/@value)">, </xsl:if>
                                    "end": "<xsl:call-template name="formatDateTime">
                                                <xsl:with-param name="dateTime" select="ccda:useablePeriod/ccda:high/@value"/>
                                            </xsl:call-template>"
                                </xsl:if>
                            }
                        </xsl:if>
                    } <xsl:if test="position() != last()">,</xsl:if>
                </xsl:for-each>
            ]
        </xsl:if>
        <xsl:if test="ccda:telecom[not(@nullFlavor)]">
            , "telecom": [
                <xsl:for-each select="ccda:telecom[not(@nullFlavor)]">
                    {
                        <xsl:if test="@value">
                            "system": "<xsl:choose>
                                    <xsl:when test="contains(@value, 'tel:')">phone</xsl:when>
                                    <xsl:when test="contains(@value, 'mailto:')">email</xsl:when>
                                    <xsl:otherwise>other</xsl:otherwise>
                                </xsl:choose>",
                        </xsl:if>
                        <xsl:if test="@use">
                            "use": "<xsl:choose>
                                <xsl:when test="@use='AS' or @use='DIR' or @use='PUB' or @use='WP'">work</xsl:when>
                                <xsl:when test="@use='BAD'">old</xsl:when>
                                <xsl:when test="@use='H' or @use='HP' or @use='HV'">home</xsl:when>
                                <xsl:when test="@use='MC' or @use='PG'">mobile</xsl:when>
                                <xsl:when test="@use='TMP'">temp</xsl:when>
                                <xsl:otherwise><xsl:value-of select="@use"/></xsl:otherwise>
                            </xsl:choose>",
                        </xsl:if>
                        "value": "<xsl:value-of select="@value"/>"
                    }
                    <xsl:if test="position() != last()">,</xsl:if>
                </xsl:for-each>
            ]
        </xsl:if>
        , "extension": [{
            "extension": [{
                "url": "ombCategory",
                "valueCoding": {
                    <xsl:choose>
                        <xsl:when test="ccda:patient/ccda:raceCode/@nullFlavor">
                            "system": "http://terminology.hl7.org/CodeSystem/v3-NullFlavor",
                            "code": "<xsl:value-of select="ccda:patient/ccda:raceCode/@nullFlavor"/>",
                            "display": "<xsl:call-template name='getNullFlavorDisplay'>
                                            <xsl:with-param name='nullFlavor' select="ccda:patient/ccda:raceCode/@nullFlavor"/>
                                        </xsl:call-template>"
                        </xsl:when>
                        <xsl:otherwise>
                            "system": "urn:oid:<xsl:value-of select="ccda:patient/ccda:raceCode/@codeSystem"/>",
                            "code": "<xsl:value-of select="ccda:patient/ccda:raceCode/@code"/>",
                            "display": "<xsl:value-of select="ccda:patient/ccda:raceCode/@displayName"/>"
                        </xsl:otherwise>
                    </xsl:choose>
                }
            },
            {
                "url": "text",
                "valueString": "<xsl:choose>
                                  <xsl:when test="ccda:patient/ccda:raceCode/@nullFlavor">
                                      <xsl:call-template name='getNullFlavorDisplay'>
                                          <xsl:with-param name='nullFlavor' select="ccda:patient/ccda:raceCode/@nullFlavor"/>
                                      </xsl:call-template>
                                  </xsl:when>
                                  <xsl:otherwise><xsl:value-of select="ccda:patient/ccda:raceCode/@displayName"/></xsl:otherwise>
                                </xsl:choose>"
            }],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
        }
        <xsl:if test="string(ccda:patient/ccda:ethnicGroupCode/@code)">
        ,{
            "extension": [{
                "url": "ombCategory",
                "valueCoding": {
                    <xsl:choose>
                        <xsl:when test="ccda:patient/ccda:ethnicGroupCode/@nullFlavor">
                            "system": "http://terminology.hl7.org/CodeSystem/v3-NullFlavor",
                            "code": "<xsl:value-of select="ccda:patient/ccda:ethnicGroupCode/@nullFlavor"/>",
                            "display": "<xsl:call-template name='getNullFlavorDisplay'>
                                            <xsl:with-param name='nullFlavor' select="ccda:patient/ccda:ethnicGroupCode/@nullFlavor"/>
                                        </xsl:call-template>"
                        </xsl:when>
                        <xsl:otherwise>
                            "system": "urn:oid:<xsl:value-of select="ccda:patient/ccda:ethnicGroupCode/@codeSystem"/>",
                            "code": "<xsl:value-of select="ccda:patient/ccda:ethnicGroupCode/@code"/>",
                            "display": "<xsl:value-of select="ccda:patient/ccda:ethnicGroupCode/@displayName"/>"
                        </xsl:otherwise>
                    </xsl:choose>
                }
            },
            {
                "url": "text",
                "valueString": "<xsl:choose>
                                  <xsl:when test="ccda:patient/ccda:ethnicGroupCode/@nullFlavor">
                                      <xsl:call-template name='getNullFlavorDisplay'>
                                          <xsl:with-param name='nullFlavor' select="ccda:patient/ccda:ethnicGroupCode/@nullFlavor"/>
                                      </xsl:call-template>
                                  </xsl:when>
                                  <xsl:otherwise><xsl:value-of select="ccda:patient/ccda:ethnicGroupCode/@displayName"/></xsl:otherwise>
                                </xsl:choose>"
            }],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
        }
        </xsl:if>
        <xsl:if test="string(ccda:patient/ccda:administrativeGenderCode/@code)">
        ,{
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
            "valueCode": "<xsl:value-of select="ccda:patient/ccda:administrativeGenderCode/@code"/>"
        }
        </xsl:if>
      ]
      , "identifier" : [{
          "type" : {
            "coding" : [{
              "system" : "http://terminology.hl7.org/CodeSystem/v2-0203",
              "code" : "MR",
              "display" : "Medical Record Number"
            }],
            "text" : "Medical Record Number"
          },
          "system" : "http://www.scn.gov/facility/<xsl:value-of select='$patientRoleId'/>",
          "value" : "<xsl:value-of select='$patientRoleId'/>"
          <xsl:if test="string($organizationResourceId)">
          , "assigner" : {
            "reference" : "Organization/<xsl:value-of select="$organizationResourceId"/>"
          }
          </xsl:if>
        },
        {
          "type" : {
            "coding" : [{
              "system" : "http://terminology.hl7.org/CodeSystem/v2-0203",
              "code" : "MA",
              "display" : "Patient Medicaid Number"
            }],
            "text" : "Patient Medicaid Number"
          },
          "system" : "http://www.medicaid.gov/",
          "value" : "<xsl:value-of select='$patientRoleId'/>"
        }
      ]
      <xsl:if test="string(ccda:patient/ccda:languageCommunication/ccda:languageCode/@code) or string(ccda:patient/ccda:languageCommunication/ccda:languageCode/@nullFlavor)">
      , "communication" : [{
        "language" : {
          <xsl:choose>            
            <xsl:when test="ccda:patient/ccda:languageCommunication/ccda:languageCode/@nullFlavor">
              "extension": [{
                "url": "http://terminology.hl7.org/CodeSystem/v3-NullFlavor",
                "valueCode": "<xsl:call-template name='getNullFlavorDisplay'>
                                  <xsl:with-param name='nullFlavor' select="ccda:patient/ccda:languageCommunication/ccda:languageCode/@nullFlavor"/>
                              </xsl:call-template>"
                }]
            </xsl:when>
            <xsl:otherwise>
              "coding" : [{
                "system" : "urn:ietf:bcp:47",
                "code" : "<xsl:value-of select="ccda:patient/ccda:languageCommunication/ccda:languageCode/@code"/>"
              }]
            </xsl:otherwise>
          </xsl:choose>
        }
        <xsl:if test="string(ccda:patient/ccda:languageCommunication/ccda:preferenceInd/@value)">
        , "preferred" : <xsl:value-of select="ccda:patient/ccda:languageCommunication/ccda:preferenceInd/@value"/>
        </xsl:if>
      }]
      </xsl:if>      
    }
    , "request" : {
        "method" : "POST",
        "url" : "<xsl:value-of select='$baseFhirUrl'/>/Patient/<xsl:value-of select='$patientResourceId'/>"
      }
  }
  </xsl:template>

  <!-- Encounter Template -->
  <xsl:template name="Encounter" match="/ccda:ClinicalDocument/ccda:encompassingEncounter">
    ,{
      "fullUrl" : "<xsl:value-of select='$baseFhirUrl'/>/Encounter/<xsl:value-of select="$encounterResourceId"/>",
      "resource": {
        "resourceType": "Encounter",
        "id": "<xsl:value-of select="$encounterResourceId"/>",
        "meta" : {
          "lastUpdated" : "<xsl:value-of select='$currentTimestamp'/>",
          "profile" : ["<xsl:value-of select='$encounterMetaProfileUrlFull'/>"]
        },
        "identifier" : [{          
          "system" : "urn:oid:<xsl:value-of select="ccda:id/@root"/>",
          "value" : "<xsl:value-of select="ccda:id/@extension"/>"
        }],
        "status": "finished",
        "type": [
          {
            <xsl:if test="string(ccda:code/ccda:translation/@code) or string(ccda:code/ccda:translation/@displayName)">
            "coding": [
              {
                "system": "<xsl:value-of select="ccda:code/ccda:translation/@codeSystem"/>",
                "code": "<xsl:value-of select="ccda:code/ccda:translation/@code"/>",
                "display": "<xsl:value-of select="ccda:code/ccda:translation/@displayName"/>"
              }
            ],
            </xsl:if>
            "text": "<xsl:value-of select="ccda:code/ccda:originalText"/>"
          }
        ],
        "class": {
          "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
          "code": "<xsl:value-of select="ccda:code/@code"/>",
          "display": "<xsl:value-of select="ccda:code/@displayName"/>"
        },
        "subject" : {
          "reference" : "Patient/<xsl:value-of select='$patientResourceId'/>",
          "display" : "<xsl:value-of select="$patientResourceName"/>"
        },
        "period": {
          "start": "<xsl:call-template name="formatDateTime">
                         <xsl:with-param name="dateTime" select="ccda:effectiveTime/ccda:low/@value"/>
                     </xsl:call-template>",
          "end": "<xsl:call-template name="formatDateTime">
                         <xsl:with-param name="dateTime" select="ccda:effectiveTime/ccda:high/@value"/>
                     </xsl:call-template>"
        }
        <xsl:if test="string(ccda:encounterParticipant/@typeCode) or string(ccda:encounterParticipant/ccda:assignedEntity/ccda:id/@extension) or string(ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:given)  or string(ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:family)">
        , "participant": [
                {
                    <xsl:if test="string(ccda:encounterParticipant/@typeCode)"> 
                    "type": [
                        {
                            "coding": [
                                {
                                    "system": "http://terminology.hl7.org/CodeSystem/v3-ParticipationType",
                                    "code": "<xsl:value-of select="ccda:encounterParticipant/@typeCode"/>",
                                    "display": "<xsl:choose>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='ADM'">admitter</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='ATND'">attender</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='CALLBCK'">callback contact</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='CON'">consultant</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='DIS'">discharger</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='ESC'">escort</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='REF'">referrer</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='SPRF'">secondary performer</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='PPRF'">primary performer</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='PART'">Participation</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='translator'">Translator</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='emergency'">Emergency</xsl:when>
                                        <xsl:otherwise>Unknown</xsl:otherwise>
                                    </xsl:choose>"                                    
                                }
                            ]
                        }
                      ]
                    </xsl:if>
                    <xsl:if test="string(ccda:encounterParticipant/ccda:assignedEntity/ccda:id/@extension) or string(ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:given)  or string(ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:family)">
                    , "individual": {
                        <xsl:if test="string(ccda:encounterParticipant/ccda:assignedEntity/ccda:id/@extension)"> 
                          "reference": "Practitioner/<xsl:value-of select="ccda:encounterParticipant/ccda:assignedEntity/ccda:id/@extension"/>",
                        </xsl:if>
                        "display": "<xsl:value-of select="concat(ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:given, ' ', ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:family)"/>"
                    }
                    </xsl:if>
                }
            ]
            <xsl:if test="string(ccda:location/ccda:healthCareFacility/ccda:id/@extension) or string(ccda:location/ccda:healthCareFacility/ccda:location/ccda:name)">
            , "location": [
                {
                    "location": {
                        <xsl:if test="string(ccda:location/ccda:healthCareFacility/ccda:id/@extension)"> 
                          "reference": "Location/<xsl:value-of select="ccda:location/ccda:healthCareFacility/ccda:id/@extension"/>",
                        </xsl:if>
                        "display": "<xsl:value-of select="ccda:location/ccda:healthCareFacility/ccda:location/ccda:name"/>"
                    }
                }
            ]
            </xsl:if>
            <xsl:if test="string(ccda:location/ccda:healthCareFacility/ccda:serviceProviderOrganization/ccda:id/@extension) or string(ccda:location/ccda:healthCareFacility/ccda:serviceProviderOrganization/ccda:name)">
            , "serviceProvider": {
                <xsl:if test="string(ccda:location/ccda:healthCareFacility/ccda:serviceProviderOrganization/ccda:id/@extension)"> 
                  "reference": "Organization/<xsl:value-of select="ccda:location/ccda:healthCareFacility/ccda:serviceProviderOrganization/ccda:id/@extension"/>",
                </xsl:if>
                "display": "<xsl:value-of select="ccda:location/ccda:healthCareFacility/ccda:serviceProviderOrganization/ccda:name"/>"
            }
            </xsl:if>
      </xsl:if>
      }      
      , "request" : {
        "method" : "POST",
        "url" : "<xsl:value-of select='$baseFhirUrl'/>/Encounter/<xsl:value-of select="$encounterResourceId"/>"
      }
    }
  </xsl:template>

  <!-- Encounter Template -->
  <xsl:template name="ComponentEncounter" match="//ccda:component/ccda:structuredBody/ccda:component/ccda:encounters/ccda:entry[position()=1]/ccda:encounter">
    ,{
      "fullUrl" : "<xsl:value-of select='$baseFhirUrl'/>/Encounter/<xsl:value-of select="$encounterResourceId"/>",
      "resource": {
        "resourceType": "Encounter",
        "id": "<xsl:value-of select="$encounterResourceId"/>",
        "meta" : {
          "lastUpdated" : "<xsl:value-of select='$currentTimestamp'/>",
          "profile" : ["<xsl:value-of select='$encounterMetaProfileUrlFull'/>"]
        },
        "identifier" : [{          
          "system" : "urn:oid:<xsl:value-of select="ccda:id/@root"/>",
          "value" : "<xsl:value-of select="ccda:id/@extension"/>"
        }],
        "status": "finished",
        <xsl:if test="string(ccda:code/ccda:translation/@code) or string(ccda:code/ccda:translation/@displayName)">
        "type": [
          {
            "coding": [
              {
                "system": "<xsl:value-of select="ccda:code/ccda:translation/@codeSystem"/>",
                "code": "<xsl:value-of select="ccda:code/ccda:translation/@code"/>",
                "display": "<xsl:value-of select="ccda:code/ccda:translation/@displayName"/>"
              }
            ]
          }
        ],
        </xsl:if>
        "class": {
          "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
          "code": "<xsl:value-of select="ccda:code/@code"/>",
          "display": "<xsl:value-of select="ccda:code/@displayName"/>"
        },
        "subject" : {
          "reference" : "Patient/<xsl:value-of select='$patientResourceId'/>",
          "display" : "<xsl:value-of select="$patientResourceName"/>"
        },
        "period": {
          "start": "<xsl:call-template name="formatDateTime">
                         <xsl:with-param name="dateTime" select="ccda:effectiveTime/ccda:low/@value"/>
                     </xsl:call-template>",
          "end": "<xsl:call-template name="formatDateTime">
                         <xsl:with-param name="dateTime" select="ccda:effectiveTime/ccda:high/@value"/>
                     </xsl:call-template>"
        }
        <xsl:if test="string(ccda:encounterParticipant/@typeCode) or string(ccda:encounterParticipant/ccda:assignedEntity/ccda:id/@extension) or string(ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:given)  or string(ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:family)">
        , "participant": [
                {
                    <xsl:if test="string(ccda:encounterParticipant/@typeCode)"> 
                    "type": [
                        {
                            "coding": [
                                {
                                    "system": "http://terminology.hl7.org/CodeSystem/v3-ParticipationType",
                                    "code": "<xsl:value-of select="ccda:encounterParticipant/@typeCode"/>",
                                    "display": "<xsl:choose>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='ADM'">admitter</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='ATND'">attender</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='CALLBCK'">callback contact</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='CON'">consultant</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='DIS'">discharger</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='ESC'">escort</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='REF'">referrer</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='SPRF'">secondary performer</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='PPRF'">primary performer</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='PART'">Participation</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='translator'">Translator</xsl:when>
                                        <xsl:when test="ccda:encounterParticipant/@typeCode='emergency'">Emergency</xsl:when>
                                        <xsl:otherwise>Unknown</xsl:otherwise>
                                    </xsl:choose>"                                    
                                }
                            ]
                        }
                      ]
                    </xsl:if>
                    <xsl:if test="string(ccda:encounterParticipant/ccda:assignedEntity/ccda:id/@extension) or string(ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:given)  or string(ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:family)">
                    , "individual": {
                        <xsl:if test="string(ccda:encounterParticipant/ccda:assignedEntity/ccda:id/@extension)"> 
                          "reference": "Practitioner/<xsl:value-of select="ccda:encounterParticipant/ccda:assignedEntity/ccda:id/@extension"/>",
                        </xsl:if>
                        "display": "<xsl:value-of select="concat(ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:given, ' ', ccda:encounterParticipant/ccda:assignedEntity/ccda:assignedPerson/ccda:name/ccda:family)"/>"
                    }
                    </xsl:if>
                }
            ]
            <xsl:if test="string(ccda:location/ccda:healthCareFacility/ccda:id/@extension) or string(ccda:location/ccda:healthCareFacility/ccda:location/ccda:name)">
            , "location": [
                {
                    "location": {
                        <xsl:if test="string(ccda:location/ccda:healthCareFacility/ccda:id/@extension)"> 
                          "reference": "Location/<xsl:value-of select="ccda:location/ccda:healthCareFacility/ccda:id/@extension"/>",
                        </xsl:if>
                        "display": "<xsl:value-of select="ccda:location/ccda:healthCareFacility/ccda:location/ccda:name"/>"
                    }
                }
            ]
            </xsl:if>
            <xsl:if test="string(ccda:location/ccda:healthCareFacility/ccda:serviceProviderOrganization/ccda:id/@extension) or string(ccda:location/ccda:healthCareFacility/ccda:serviceProviderOrganization/ccda:name)">
            , "serviceProvider": {
                <xsl:if test="string(ccda:location/ccda:healthCareFacility/ccda:serviceProviderOrganization/ccda:id/@extension)"> 
                  "reference": "Organization/<xsl:value-of select="ccda:location/ccda:healthCareFacility/ccda:serviceProviderOrganization/ccda:id/@extension"/>",
                </xsl:if>
                "display": "<xsl:value-of select="ccda:location/ccda:healthCareFacility/ccda:serviceProviderOrganization/ccda:name"/>"
            }
            </xsl:if>
      </xsl:if>
      }      
      , "request" : {
        "method" : "POST",
        "url" : "<xsl:value-of select='$baseFhirUrl'/>/Encounter/<xsl:value-of select="$encounterResourceId"/>"
      }
    }
  </xsl:template>

  <!-- Consent Template -->
  <xsl:template name="Consent" match="/ccda:ClinicalDocument/ccda:consent">
    ,{
      "fullUrl" : "<xsl:value-of select='$baseFhirUrl'/>/Consent/<xsl:value-of select='$consentResourceId'/>",
      "resource": {
        "resourceType": "Consent",
        "id": "<xsl:value-of select='$consentResourceId'/>",
        "meta" : {
          "lastUpdated" : "<xsl:value-of select='$currentTimestamp'/>",
          "profile" : ["<xsl:value-of select='$consentMetaProfileUrlFull'/>"]
        },
        "status": "<xsl:choose>
                      <xsl:when test="ccda:statusCode/@code='active'">active</xsl:when>
                      <xsl:when test="ccda:statusCode/@code='completed'">active</xsl:when>
                      <xsl:when test="ccda:statusCode/@code='aborted'">not-done</xsl:when>
                      <xsl:when test="ccda:statusCode/@code='nullified'">entered-in-error</xsl:when>
                      <xsl:when test="ccda:statusCode/@code='held'">draft</xsl:when>
                      <xsl:when test="ccda:statusCode/@code='suspended'">inactive</xsl:when>
                      <xsl:otherwise>unknown</xsl:otherwise>
                  </xsl:choose>",
        "scope": {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/consentscope",
                            "code": "treatment",
                            "display": "Treatment"
                        }
                    ],
                    "text": "treatment"
                },
        "category": [
                    {
                        "coding": [
                            {
                                "system": "http://loinc.org",
                                "code": "59284-0",
                                "display": "Consent Document"
                            }
                        ]
                    },
                    {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                                "code": "IDSCL"
                            }
                        ]
                    }
                ]
        <xsl:if test="ccda:effectiveTime/@value or $currentTimestamp">
            , "dateTime": "<xsl:choose>
                                <xsl:when test="ccda:effectiveTime/@value">
                                    <xsl:call-template name="formatDateTime">
                                        <xsl:with-param name="dateTime" select="ccda:effectiveTime/@value"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$currentTimestamp"/>
                                </xsl:otherwise>
                            </xsl:choose>"
        </xsl:if>
        , "patient" : {
            "reference" : "Patient/<xsl:value-of select='$patientResourceId'/>"
        }
        , "organization" : [{
          "reference" : "Organization/<xsl:value-of select='$organizationResourceId'/>"
        }]
        , "provision" : {
              "type" : "<xsl:choose>
                            <xsl:when test="contains(string(ccda:code/@displayName), 'deny')">deny</xsl:when>
                            <xsl:otherwise>permit</xsl:otherwise>
                        </xsl:choose>"
        }
        , "policy" : [{
            "authority" : "urn:uuid:d1eaac1a-22b7-4bb6-9c62-cc95d6fdf1a5"
          }]
        , "sourceAttachment" : {
          "contentType" : "application/pdf",
          "language" : "en"
        }
      },
      "request" : {
        "method" : "POST",
        "url" : "<xsl:value-of select='$baseFhirUrl'/>/Consent/<xsl:value-of select='$consentResourceId'/>"
      }
    }
  </xsl:template>

  <!-- Organization Template -->
  <xsl:template name="Organization" match="/ccda:ClinicalDocument/ccda:author">
    ,{
      "fullUrl" : "<xsl:value-of select='$baseFhirUrl'/>/Organization/<xsl:value-of select="$organizationResourceId"/>",
      "resource": {
        "resourceType": "Organization",
        "id": "<xsl:value-of select="$organizationResourceId"/>",
        "meta" : {
          "lastUpdated" : "<xsl:value-of select='$currentTimestamp'/>",
          "profile" : ["<xsl:value-of select='$organizationMetaProfileUrlFull'/>"]
        },
        "active": true,
        <xsl:if test="string(ccda:assignedAuthor/ccda:representedOrganization/ccda:name) or string(ccda:assignedAuthor/ccda:representedOrganization/ccda:id/@extension)">
        "identifier": [
          {
            "type" : {
              "coding": [
                {
                  "system" : "urn:oid:<xsl:value-of select="ccda:assignedAuthor/ccda:representedOrganization/ccda:id/@root"/>",
                  "code" : "<xsl:value-of select="ccda:assignedAuthor/ccda:representedOrganization/ccda:id/@extension"/>",
                  "display": "<xsl:value-of select="ccda:assignedAuthor/ccda:representedOrganization/ccda:name"/>"
                }
              ]
            },
            "system" : "http://www.hl7.org/oid/",
            "value" : "<xsl:value-of select="ccda:assignedAuthor/ccda:representedOrganization/ccda:id/@extension"/>"
          }
        ],
        </xsl:if>
        "name" : "<xsl:value-of select="ccda:assignedAuthor/ccda:representedOrganization/ccda:name"/>"
        <xsl:if test="ccda:assignedAuthor/ccda:representedOrganization/ccda:telecom[not(@nullFlavor)]">
            , "telecom": [
                <xsl:for-each select="ccda:assignedAuthor/ccda:representedOrganization/ccda:telecom[not(@nullFlavor)]">
                    {
                        <xsl:if test="@value">
                            "system": "<xsl:choose>
                                    <xsl:when test="contains(@value, 'tel:')">phone</xsl:when>
                                    <xsl:when test="contains(@value, 'mailto:')">email</xsl:when>
                                    <xsl:otherwise>other</xsl:otherwise>
                                </xsl:choose>",
                        </xsl:if>
                        <xsl:if test="@use">
                            "use": "<xsl:choose>
                                <xsl:when test="@use='AS' or @use='DIR' or @use='PUB' or @use='WP'">work</xsl:when>
                                <xsl:when test="@use='BAD'">old</xsl:when>
                                <xsl:when test="@use='H' or @use='HP' or @use='HV'">home</xsl:when>
                                <xsl:when test="@use='MC' or @use='PG'">mobile</xsl:when>
                                <xsl:when test="@use='TMP'">temp</xsl:when>
                                <xsl:otherwise><xsl:value-of select="@use"/></xsl:otherwise>
                            </xsl:choose>",
                        </xsl:if>
                        "value": "<xsl:value-of select="@value"/>"
                    }
                    <xsl:if test="position() != last()">,</xsl:if>
                </xsl:for-each>
            ]
        </xsl:if>
        <xsl:if test="ccda:assignedAuthor/ccda:representedOrganization/ccda:addr[not(@nullFlavor)]">
            , "address": [
                <xsl:for-each select="ccda:assignedAuthor/ccda:representedOrganization/ccda:addr[not(@nullFlavor)]">
                    {
                        <xsl:if test="@use">
                            "use": "<xsl:choose>
                                <xsl:when test="@use='HP' or @use='H'">home</xsl:when>
                                <xsl:when test="@use='WP'">work</xsl:when>
                                <xsl:when test="@use='TMP'">temp</xsl:when>
                                <xsl:when test="@use='OLD' or @use='BAD'">old</xsl:when>
                                <xsl:otherwise><xsl:value-of select="@use"/></xsl:otherwise>
                            </xsl:choose>",
                        </xsl:if>
                        <xsl:if test="string(ccda:streetAddressLine) or string(ccda:city) or string(ccda:state) or string(ccda:postalCode)">
                            "text": "<xsl:for-each select="ccda:streetAddressLine">
                                  <xsl:value-of select="."/>
                                  <xsl:if test="position() != last()">, </xsl:if>
                              </xsl:for-each>
                              <xsl:if test="string(ccda:city)"> <xsl:text> </xsl:text><xsl:value-of select="ccda:city"/></xsl:if>
                              <xsl:if test="string(ccda:state)">, <xsl:value-of select="ccda:state"/></xsl:if>
                              <xsl:if test="string(ccda:postalCode)"> <xsl:text> </xsl:text><xsl:value-of select="ccda:postalCode"/></xsl:if>" ,
                        </xsl:if>
                        <xsl:if test="ccda:streetAddressLine">
                            "line": [
                                <xsl:for-each select="ccda:streetAddressLine">
                                    "<xsl:value-of select="."/>"
                                    <xsl:if test="position() != last()">, </xsl:if>
                                </xsl:for-each>
                            ]
                        </xsl:if>
                        <xsl:if test="string(ccda:city)">
                            , "city": "<xsl:value-of select="ccda:city"/>"
                        </xsl:if>
                        <xsl:if test="string(ccda:county)">
                            , "district": "<xsl:value-of select="ccda:county"/>"
                        </xsl:if>
                        <xsl:if test="string(ccda:state)">
                            , "state": "<xsl:value-of select="ccda:state"/>"
                        </xsl:if>
                        <xsl:if test="string(ccda:postalCode)">
                            , "postalCode": "<xsl:value-of select="ccda:postalCode"/>"
                        </xsl:if>
                        <xsl:if test="string(ccda:country)">
                            , "country": "<xsl:value-of select="ccda:country"/>"
                        </xsl:if>
                        <xsl:if test="ccda:useablePeriod">
                            ,"period": {
                                <xsl:if test="string(ccda:useablePeriod/ccda:low/@value)">
                                    "start": "<xsl:call-template name="formatDateTime">
                                                  <xsl:with-param name="dateTime" select="ccda:useablePeriod/ccda:low/@value"/>
                                              </xsl:call-template>"
                                </xsl:if>
                                <xsl:if test="string(ccda:useablePeriod/ccda:high/@value)">
                                    <xsl:if test="string(ccda:useablePeriod/ccda:low/@value)">, </xsl:if>
                                    "end": "<xsl:call-template name="formatDateTime">
                                                <xsl:with-param name="dateTime" select="ccda:useablePeriod/ccda:high/@value"/>
                                            </xsl:call-template>"
                                </xsl:if>
                            }
                        </xsl:if>
                    } <xsl:if test="position() != last()">,</xsl:if>
                </xsl:for-each>
            ]
        </xsl:if>
      },
      "request" : {
        "method" : "POST",
        "url" : "<xsl:value-of select='$baseFhirUrl'/>/Organization/<xsl:value-of select="$organizationResourceId"/>"
      }
    }
  </xsl:template>

  <!-- Sexual orientation Observation Template -->
  <xsl:template name="SexualOrientation" match="ccda:sexualOrientation/ccda:entry/ccda:observation">
    <xsl:if test="ccda:code/@code and string(ccda:code/@code) = '76690-7'">
      ,{
        "fullUrl" : "<xsl:value-of select='$baseFhirUrl'/>/Observation/<xsl:value-of select='$sexualOrientationResourceId'/>",
        "resource": {
          "resourceType": "Observation",
          "id": "<xsl:value-of select='$sexualOrientationResourceId'/>",
          "meta" : {
            "lastUpdated" : "<xsl:value-of select='$currentTimestamp'/>",
            "profile" : ["<xsl:value-of select='$observationSexualOrientationMetaProfileUrlFull'/>"]
          },
          "status": "<xsl:call-template name='mapObservationStatus'>
                        <xsl:with-param name='statusCode' select='ccda:statusCode/@code'/>
                    </xsl:call-template>",
          "category": [
            {
              "coding": [{
                  "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                  "code": "social-history",
                  "display": "Social History"
              }]
            }
          ],
          "code": {
            "coding": [
              {
                "system": "http://loinc.org",
                "code": "<xsl:value-of select='ccda:code/@code'/>",
                "display": "<xsl:value-of select='ccda:code/@displayName'/>"
              }
            ],
            "text" : "<xsl:value-of select='ccda:code/ccda:originalText'/>"
          },
          <xsl:choose>
            <xsl:when test="string(ccda:value/@code) = 'UNK' or string(ccda:value/@code) = ''">
              "valueCodeableConcept" : {
                "coding" : [{
                  "system" : "http://terminology.hl7.org/CodeSystem/v3-NullFlavor",
                  "code" : "UNK",
                  "display" : "Unknown"
                }]
              },
            </xsl:when>
            <xsl:otherwise>
              "valueCodeableConcept" : {
                "coding" : [{
                  "system" : "http://loinc.org",
                  "code" : "<xsl:value-of select='ccda:value/@code'/>",
                  "display" : "<xsl:value-of select='ccda:value/@displayName'/>"
                }]
              },
            </xsl:otherwise>
          </xsl:choose>
          "subject": {
            "reference": "Patient/<xsl:value-of select='$patientResourceId'/>",
            "display" : "<xsl:value-of select="$patientResourceName"/>"
          }
          <xsl:if test="ccda:effectiveTime/@value or $currentTimestamp">
            , "effectiveDateTime": "<xsl:choose>
                                      <xsl:when test="ccda:effectiveTime/@value">
                                          <xsl:call-template name="formatDateTime">
                                              <xsl:with-param name="dateTime" select="ccda:effectiveTime/@value"/>
                                          </xsl:call-template>
                                      </xsl:when>
                                      <xsl:otherwise>
                                          <xsl:value-of select="$currentTimestamp"/>
                                      </xsl:otherwise>
                                  </xsl:choose>"
          </xsl:if>     
        },
        "request" : {
          "method" : "POST",
          "url" : "<xsl:value-of select='$baseFhirUrl'/>/Observation/<xsl:value-of select='$sexualOrientationResourceId'/>"
        }
      }
    </xsl:if>
  </xsl:template>

  <!-- Observation Template -->
  <xsl:template name="Observation" match="ccda:observations/ccda:entry">
    <xsl:if test="string(ccda:observation/ccda:code/@code) != '76690-7'">
      <xsl:variable name="observationResourceId">
        <xsl:call-template name="generateFixedLengthResourceId">
          <xsl:with-param name="prefixString" select="concat(generate-id(ccda:observation/ccda:code/@code), position())"/>
          <xsl:with-param name="sha256ResourceId" select="$observationResourceSha256Id"/>
        </xsl:call-template>
      </xsl:variable>
      ,{
        "fullUrl": "<xsl:value-of select='$baseFhirUrl'/>/Observation/<xsl:value-of select='$observationResourceId'/>",
        "resource": {
          "resourceType": "Observation",
          "id": "<xsl:value-of select='$observationResourceId'/>",
          "meta": {
            "lastUpdated": "<xsl:value-of select='$currentTimestamp'/>",
            "profile": ["<xsl:value-of select='$observationMetaProfileUrlFull'/>"]
          },
          "status": "<xsl:call-template name='mapObservationStatus'>
                        <xsl:with-param name='statusCode' select='ccda:observation/ccda:statusCode/@code'/>
                    </xsl:call-template>",
          "category": [
            {
              "coding": [{
                  "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                  "code": "social-history"
              }]
            },
            {
              "coding": [{
                  "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                  "code": "survey"
              }]
            }
          ],
          "code": {
            "coding": [
              {
                "system": "http://loinc.org",
                "code": "<xsl:value-of select='ccda:observation/ccda:code/@code'/>",
                "display": "<xsl:value-of select='ccda:observation/ccda:code/@displayName'/>"
              }
            ],
            "text": "<xsl:value-of select='ccda:observation/ccda:code/ccda:originalText'/>"
          },
          <xsl:choose>
            <xsl:when test="string(ccda:observation/ccda:value/@code) = 'UNK' or string(ccda:observation/ccda:value/@code) = ''">
              "valueCodeableConcept" : {
                "coding": [{
                  "system": "http://terminology.hl7.org/CodeSystem/v3-NullFlavor",
                  "code": "UNK",
                  "display": "Unknown"
                }]
              },
            </xsl:when>
            <xsl:otherwise>
              "valueCodeableConcept" : {
                "coding": [{
                  "system": "http://loinc.org",
                  "code": "<xsl:value-of select='ccda:observation/ccda:value/@code'/>",
                  "display": "<xsl:value-of select='ccda:observation/ccda:value/@displayName'/>"
                }],
                "text": "<xsl:value-of select='ccda:observation/ccda:value/@displayName'/>"
              },
            </xsl:otherwise>
          </xsl:choose>
          "subject": {
            "reference": "Patient/<xsl:value-of select='$patientResourceId'/>",
            "display": "<xsl:value-of select="$patientResourceName"/>"
          }
          <xsl:if test="normalize-space($encounterResourceId) != '' and $encounterResourceId != 'null'">
          , "encounter": {
              "reference": "Encounter/<xsl:value-of select='$encounterResourceId'/>"
            }
          </xsl:if>
          <xsl:if test="ccda:observation/ccda:effectiveTime/@value or $currentTimestamp">
            , "effectiveDateTime": "<xsl:choose>
                                      <xsl:when test="ccda:observation/ccda:effectiveTime/@value">
                                          <xsl:call-template name="formatDateTime">
                                              <xsl:with-param name="dateTime" select="ccda:observation/ccda:effectiveTime/@value"/>
                                          </xsl:call-template>
                                      </xsl:when>
                                      <xsl:otherwise>
                                          <xsl:value-of select="$currentTimestamp"/>
                                      </xsl:otherwise>
                                  </xsl:choose>"
          </xsl:if>
          <xsl:if test="string($organizationResourceId)">
          , "performer": [{
                        "reference": "Organization/<xsl:value-of select='$organizationResourceId'/>"
                    }]
          </xsl:if>
        },
        "request": {
          "method": "POST",
          "url": "<xsl:value-of select='$baseFhirUrl'/>/Observation/<xsl:value-of select='$observationResourceId'/>"
        }
      }
      <!-- Apply the same observation data in the QuestionnaireResponse mode -->
        <xsl:apply-templates select="." mode="questionnaireresponse"/>
    </xsl:if>
  </xsl:template>

  <!-- Template to generate Questionnaire resource -->
  <xsl:template name="QuestionnaireResource" match="ccda:Questionnaire"> 
      ,{
          "fullUrl" : "<xsl:value-of select='$baseFhirUrl'/>/Questionnaire/<xsl:value-of select='$questionnaireResourceId'/>",
          "resource" : {
            "resourceType": "Questionnaire",
            "id": "<xsl:value-of select='$questionnaireResourceId'/>",
            "meta" : {
              "lastUpdated" : "<xsl:value-of select='$currentTimestamp'/>",
              "profile" : ["<xsl:value-of select='$questionnaireMetaProfileUrlFull'/>"]
            },
            <xsl:if test="string(ccda:entry/ccda:observation/ccda:code/@codeSystem) or string(ccda:entry/ccda:observation/ccda:code/@code)">
            "identifier" : [{
              <xsl:if test="string(ccda:entry/ccda:observation/ccda:code/@codeSystem)">
              "system" : "urn:<xsl:value-of select='ccda:entry/ccda:observation/ccda:code/@codeSystem'/>",
              </xsl:if>
              "value" : "<xsl:value-of select='ccda:entry/ccda:observation/ccda:code/@code'/>"
            }],
            </xsl:if>
            "status": "<xsl:call-template name='mapQuestionnaireStatus'>
                        <xsl:with-param name='statusCode' select='ccda:entry/ccda:observation/ccda:statusCode/@code'/>
                    </xsl:call-template>",
            "title": "<xsl:value-of select='ccda:title'/>"
            <xsl:if test="string(ccda:entry/ccda:observation/ccda:entryRelationship/ccda:observation)">
              ,"item": [
                  <xsl:for-each select="ccda:entry/ccda:observation/ccda:entryRelationship/ccda:observation">
                      {
                          "linkId": "<xsl:value-of select='ccda:code/@code'/>",
                          "code" : [{
                            "system" : "<xsl:value-of select='ccda:code/@codeSystem'/>",
                            "code" : "<xsl:value-of select='ccda:code/@code'/>",
                            "display" : "<xsl:value-of select='ccda:code/@displayName'/>"
                          }],
                          "text": "<xsl:value-of select='ccda:value/@displayName'/>",
                          "type": "string"
                      }
                      <xsl:if test="position() != last()">,</xsl:if>
                  </xsl:for-each>
              ]
            </xsl:if>
          },
          "request" : {
            "method" : "POST",
            "url" : "<xsl:value-of select='$baseFhirUrl'/>/Questionnaire/<xsl:value-of select='$questionnaireResourceId'/>"
          }
      }
  </xsl:template>

  <!-- Template to generate QuestionnaireResponse resource -->
  <xsl:template name="QuestionnaireResponseResource" match="ccda:observations/ccda:entry/ccda:observation" mode="questionnaireresponse">
      <xsl:variable name="QuestionnaireResponseResourceId">
        <xsl:call-template name="generateFixedLengthResourceId">
          <xsl:with-param name="prefixString" select="concat(generate-id(ccda:code/@code), position())"/>
          <xsl:with-param name="sha256ResourceId" select="$questionnaireResponseResourceSha256Id"/>
        </xsl:call-template>
      </xsl:variable>
      ,{
          "fullUrl" : "<xsl:value-of select='$baseFhirUrl'/>/QuestionnaireResponse/<xsl:value-of select='$QuestionnaireResponseResourceId'/>",
          "resource" : {
            "resourceType": "QuestionnaireResponse",
            "id": "<xsl:value-of select='$QuestionnaireResponseResourceId'/>",
            "status": "completed",
            "subject": {
                "reference": "Patient/<xsl:value-of select='$patientResourceId'/>"
            }
            <xsl:if test="normalize-space($encounterResourceId) != '' and $encounterResourceId != 'null'">
            , "encounter": {
                "reference": "Encounter/<xsl:value-of select='$encounterResourceId'/>"
              }
            </xsl:if>
            <xsl:if test="string(ccda:code/@code)">
              ,"item": [
                  {
                      "linkId": "<xsl:value-of select='ccda:code/@code'/>",
                      "text": "<xsl:value-of select='ccda:code/ccda:originalText'/>"
                      <xsl:if test="string(ccda:value/@code) or string(ccda:value/@displayName)">
                        ,"answer" : [{
                          "valueCoding" : {
                            "system" : "http://loinc.org",
                            "code" : "<xsl:value-of select='ccda:value/@code'/>",
                            "display" : "<xsl:value-of select='ccda:value/@displayName'/>"
                          }
                        }]                          
                      </xsl:if>
                      <xsl:if test="string(ccda:entryRelationship/ccda:observation/ccda:code/@code)">
                      , "item": [
                      <xsl:for-each select="ccda:entryRelationship/ccda:observation">
                        {
                              "linkId": "<xsl:value-of select='ccda:code/@code'/>",
                              "text": "<xsl:value-of select='ccda:code/ccda:originalText'/>"
                              <xsl:if test="string(ccda:value/@code) or string(ccda:value/@displayName)">
                                ,"answer" : [{
                                  "valueCoding" : {
                                    "system" : "http://loinc.org",
                                    "code" : "<xsl:value-of select='ccda:value/@code'/>",
                                    "display" : "<xsl:value-of select='ccda:value/@displayName'/>"
                                  }
                                }]
                              </xsl:if>                          
                          }
                          <xsl:if test="position() != last()">,</xsl:if>
                      </xsl:for-each>
                      ]
                      </xsl:if>
                  }
              ]
            </xsl:if>
          },
          "request" : {
            "method" : "POST",
            "url" : "<xsl:value-of select='$baseFhirUrl'/>/QuestionnaireResponse/<xsl:value-of select='$QuestionnaireResponseResourceId'/>"
          }
      }
  </xsl:template>

  <xsl:template name="formatDateTime">
      <xsl:param name="dateTime"/>
      <xsl:choose>
          <!-- If format is YYYYMMDDHHMMSS -->
          <xsl:when test="string-length($dateTime) >= 14">
              <xsl:value-of select="concat(
                  substring($dateTime, 1, 4), '-', 
                  substring($dateTime, 5, 2), '-', 
                  substring($dateTime, 7, 2), 'T', 
                  substring($dateTime, 9, 2), ':', 
                  substring($dateTime, 11, 2), ':', 
                  substring($dateTime, 13, 2),
                  'Z'
              )"/>
          </xsl:when>
          <!-- If format is YYYYMMDD -->
          <xsl:when test="string-length($dateTime) >= 8">
              <xsl:value-of select="concat(
                  substring($dateTime, 1, 4), '-', 
                  substring($dateTime, 5, 2), '-', 
                  substring($dateTime, 7, 2), 'T00:00:00Z'
              )"/>
          </xsl:when>
          <!-- If format is unknown, return as is -->
          <xsl:otherwise>
              <xsl:value-of select="$dateTime"/>
          </xsl:otherwise>
      </xsl:choose>
  </xsl:template>

  <xsl:template name="getNullFlavorDisplay">
    <xsl:param name="nullFlavor"/>
    <xsl:choose>
        <xsl:when test="$nullFlavor = 'NI'">unknown</xsl:when>
        <xsl:when test="$nullFlavor = 'UNK'">unknown</xsl:when>
        <xsl:when test="$nullFlavor = 'ASKU'">asked-unknown</xsl:when>
        <xsl:when test="$nullFlavor = 'NASK'">not-asked</xsl:when>
        <xsl:when test="$nullFlavor = 'NAV'">temp-unknown</xsl:when>
        <xsl:when test="$nullFlavor = 'OTH'">unsupported</xsl:when>
        <xsl:when test="$nullFlavor = 'MSK'">masked</xsl:when>
        <xsl:when test="$nullFlavor = 'NA'">not-applicable</xsl:when>
        <xsl:otherwise>unknown</xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="mapObservationStatus">
    <xsl:param name="statusCode"/>
    <xsl:choose>
        <xsl:when test="$statusCode = 'completed'">final</xsl:when>
        <xsl:when test="$statusCode = 'final'">final</xsl:when>
        <xsl:when test="$statusCode = 'active'">preliminary</xsl:when>
        <xsl:when test="$statusCode = 'aborted'">cancelled</xsl:when>
        <xsl:when test="$statusCode = 'cancelled'">cancelled</xsl:when>
        <xsl:when test="$statusCode = 'held'">registered</xsl:when>
        <xsl:when test="$statusCode = 'suspended'">registered</xsl:when>
        <xsl:when test="$statusCode = 'nullified'">entered-in-error</xsl:when>
        <xsl:otherwise>unknown</xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="mapQuestionnaireStatus">
    <xsl:param name="statusCode"/>
    <xsl:choose>
        <xsl:when test="$statusCode = 'completed'">active</xsl:when>
        <xsl:when test="$statusCode = 'final'">active</xsl:when>
        <xsl:when test="$statusCode = 'active'">active</xsl:when>
        <xsl:when test="$statusCode = 'aborted'">retired</xsl:when>
        <xsl:when test="$statusCode = 'cancelled'">retired</xsl:when>
        <xsl:when test="$statusCode = 'held'">draft</xsl:when>
        <xsl:when test="$statusCode = 'suspended'">draft</xsl:when>
        <xsl:when test="$statusCode = 'nullified'">retired</xsl:when>
        <xsl:otherwise>unknown</xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Reusable ID generator template -->
<xsl:template name="generateFixedLengthResourceId">
  <xsl:param name="prefixString"/>
  <xsl:param name="sha256ResourceId"/>

  <xsl:variable name="trimmedHashId" select="substring(concat($prefixString, $sha256ResourceId), 1, 64)"/>
  <xsl:variable name="resourceUId" select="$trimmedHashId"/>
  <xsl:copy-of select="$resourceUId"/>
</xsl:template>

<xsl:template name="generateNameJson">
    <xsl:param name="selectedName"/>
    {
        <xsl:if test="string($selectedName/ccda:given)">
            "extension": [{
              "url": "<xsl:value-of select='$baseFhirUrl'/>/StructureDefinition/middle-name",
              "valueString" : "<xsl:value-of select="$selectedName/ccda:given"/>"
            }]
        </xsl:if>
        <xsl:if test="$selectedName/@use">
            <xsl:if test="string($selectedName/ccda:given)">, </xsl:if>
            "use": "<xsl:choose>
                <xsl:when test="$selectedName/@use='L'">official</xsl:when>
                <xsl:when test="$selectedName/@use='P'">usual</xsl:when>
                <xsl:otherwise><xsl:value-of select="$selectedName/@use"/></xsl:otherwise>
            </xsl:choose>"
        </xsl:if>                        
        <xsl:if test="string($selectedName/ccda:prefix)"> 
            <xsl:if test="string($selectedName/ccda:given) or string($selectedName/ccda:prefix)">, </xsl:if>
            "prefix": ["<xsl:value-of select='$selectedName/ccda:prefix'/>"]
        </xsl:if>
        <xsl:if test="string($selectedName/ccda:given)"> 
            <xsl:if test="string($selectedName/ccda:given) or string($selectedName/ccda:prefix) or string($selectedName/ccda:prefix)">, </xsl:if>
            "given": ["<xsl:value-of select='$selectedName/ccda:given'/>"]
        </xsl:if>
        <xsl:if test="string($selectedName/ccda:family)"> 
            <xsl:if test="string($selectedName/ccda:given) or string($selectedName/ccda:prefix) or string($selectedName/ccda:prefix) or string($selectedName/ccda:given)">, </xsl:if>
            "family": "<xsl:value-of select='$selectedName/ccda:family'/>"
        </xsl:if>
        <xsl:if test="string($selectedName/ccda:suffix)">
            <xsl:if test="string($selectedName/ccda:given) or string($selectedName/ccda:prefix) or string($selectedName/ccda:prefix) or string($selectedName/ccda:given) or string($selectedName/ccda:family)">, </xsl:if>
            "suffix": ["<xsl:value-of select='$selectedName/ccda:suffix'/>"]
        </xsl:if>
        <xsl:if test="($selectedName/ccda:validTime/ccda:low and not($selectedName/ccda:validTime/ccda:low/@nullFlavor = 'UNK' or $selectedName/ccda:validTime/ccda:low/@nullFlavor = 'NA')) or 
                  ($selectedName/ccda:validTime/ccda:high and not($selectedName/ccda:validTime/ccda:high/@nullFlavor = 'UNK' or $selectedName/ccda:validTime/ccda:high/@nullFlavor = 'NA'))">
          <xsl:if test="string($selectedName/ccda:given) or string($selectedName/ccda:prefix) or string($selectedName/ccda:family) or string($selectedName/ccda:suffix)">, </xsl:if>
          "period": {
              <xsl:if test="$selectedName/ccda:validTime/ccda:low and not($selectedName/ccda:validTime/ccda:low/@nullFlavor = 'UNK' or $selectedName/ccda:validTime/ccda:low/@nullFlavor = 'NA')">
                  "start": "<xsl:call-template name="formatDateTime">
                                <xsl:with-param name="dateTime" select="$selectedName/ccda:validTime/ccda:low/@value"/>
                            </xsl:call-template>"
                  <xsl:if test="$selectedName/ccda:validTime/ccda:high and not($selectedName/ccda:validTime/ccda:high/@nullFlavor = 'UNK' or $selectedName/ccda:validTime/ccda:high/@nullFlavor = 'NA')">,</xsl:if>
              </xsl:if>
              <xsl:if test="$selectedName/ccda:validTime/ccda:high and not($selectedName/ccda:validTime/ccda:high/@nullFlavor = 'UNK' or $selectedName/ccda:validTime/ccda:high/@nullFlavor = 'NA')">
                  "end": "<xsl:call-template name="formatDateTime">
                              <xsl:with-param name="dateTime" select="$selectedName/ccda:validTime/ccda:high/@value"/>
                          </xsl:call-template>"
              </xsl:if>
          }
        </xsl:if>
    }
</xsl:template>
</xsl:stylesheet>