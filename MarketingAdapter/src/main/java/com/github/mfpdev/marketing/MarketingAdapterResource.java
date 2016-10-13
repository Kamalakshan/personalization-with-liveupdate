/**
 * Copyright 2016 IBM Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.github.mfpdev.marketing;

import com.ibm.json.java.JSONObject;
import io.swagger.annotations.*;

import java.io.*;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;

@Api(value = "Marketing adapter")
@Path("/deals")
public class MarketingAdapterResource {

	static Logger logger = Logger.getLogger(MarketingAdapterResource.class.getName());

	@GET
	@Produces(MediaType.APPLICATION_JSON)
	@Path("/{category}")
	@ApiOperation(value = "Array of deals", notes = "Returns array of deals for specific stores category")
	@ApiResponses(value = { @ApiResponse(code = 200, message = "Array of deals returned as JSON"),@ApiResponse(code = 404, message = "Array of deals not found") })
	public JSONObject enterInfo(@ApiParam(value = "The Branch Category (e.g: super/my-super/gas-station/pharmacy)", required = true) @PathParam("category") String storeCategory) {
		JSONObject result;
		try {
			InputStream json = this.getClass().getResource("/json/" + storeCategory + ".json").openStream();
			result = JSONObject.parse(new BufferedInputStream(json));
		} catch (Exception e) {
			logger.log(Level.WARNING, "Cannot load " + storeCategory + ".json " + e.getMessage(), e);
			throw new NotFoundException();
		}
		return result;
	}
}
