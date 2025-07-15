/**
 * Teleport
 * Copyright (C) 2023  Gravitational, Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import React, { useState } from 'react';
import { ButtonIcon, ButtonPrimary, ButtonSecondary, Flex, H2, Text, Box, LabelInput, TextArea } from 'design';
import { Danger } from 'design/Alert';
import Dialog, { DialogContent } from 'design/Dialog';
import { Cross } from 'design/Icon';

export type Props = {
  open: boolean;
  onSave: (script: string) => void;
  onClose: () => void;
  initialScript?: string;
  serverName?: string;
};

export default function InitScriptDialog({
  open,
  onSave,
  onClose,
  initialScript = '',
  serverName = '',
}: Props) {
  const [script, setScript] = useState(initialScript);
  const [attempt, setAttempt] = useState({ isProcessing: false, isSuccess: false, message: '' });

  const handleSave = async () => {
    console.log('handleSave called with script:', script);
    setAttempt({ isProcessing: true, isSuccess: false, message: '' });
    
    try {
      // Basic validation
      if (script.length > 32768) {
        throw new Error('Init script exceeds maximum length of 32KB');
      }
      
      // Check for dangerous patterns
      const dangerousPatterns = [
        'rm -rf /',
        'rm -rf /*',
        ':(){ :|:& };:',
        'mkfs.',
        '/dev/sd',
        'dd if=',
      ];
      
      const scriptLower = script.toLowerCase();
      for (const pattern of dangerousPatterns) {
        if (scriptLower.includes(pattern)) {
          throw new Error(`Init script contains potentially dangerous pattern: ${pattern}`);
        }
      }
      
      await onSave(script);
      setAttempt({ isProcessing: false, isSuccess: true, message: '' });
      onClose();
    } catch (error) {
      setAttempt({ 
        isProcessing: false, 
        isSuccess: false, 
        message: error.message 
      });
    }
  };

  const handleClose = () => {
    setScript(initialScript);
    setAttempt({ isProcessing: false, isSuccess: false, message: '' });
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose}>
      <DialogContent>
        <Flex justifyContent="space-between" alignItems="center" mb={4}>
          <H2>Edit Init Script{serverName && ` for ${serverName}`}</H2>
          <ButtonIcon size={1} onClick={handleClose}>
            <Cross size="medium" />
          </ButtonIcon>
        </Flex>
        
        <Box mb={3}>
          <Text typography="body1" color="text.main">
            Configure a script that will be executed automatically when users start a shell session on this server.
            The script runs before the user shell starts.
          </Text>
        </Box>
        
        {attempt.message && (
          <Danger mb={3}>
            {attempt.message}
          </Danger>
        )}
        
        <Box mb={3}>
          <LabelInput mb={1}>
            <Text typography="body3" mb={1}>
              Init Script
            </Text>
            <TextArea
              placeholder="#!/bin/bash&#10;echo 'Welcome to the server!'&#10;# Add your initialization commands here"
              value={script}
              onChange={e => setScript(e.target.value)}
              rows={12}
            />
          </LabelInput>
          <Text typography="body3" color="text.muted" mt={1}>
            Maximum 32KB. Be careful with script content - avoid dangerous operations.
          </Text>
        </Box>
        
        <Flex gap={2} mt={4}>
          <ButtonSecondary onClick={handleClose}>
            Cancel
          </ButtonSecondary>
          <ButtonPrimary 
            onClick={handleSave}
            disabled={attempt.isProcessing}
          >
            {attempt.isProcessing ? 'Saving...' : 'Save'}
          </ButtonPrimary>
        </Flex>
      </DialogContent>
    </Dialog>
  );
}

